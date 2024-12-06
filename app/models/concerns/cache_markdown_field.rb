# frozen_string_literal: true

# This module takes care of updating cache columns for Markdown-containing
# fields. Use like this in the body of your class:
#
#     include CacheMarkdownField
#     cache_markdown_field :foo
#     cache_markdown_field :bar
#     cache_markdown_field :baz, pipeline: :single_line
#     cache_markdown_field :baz, whitelisted: true
#
# Corresponding foo_html, bar_html and baz_html fields should exist.
module CacheMarkdownField
  extend ActiveSupport::Concern

  # changes to these attributes cause the cache to be invalidates
  INVALIDATED_BY = %w[author project].freeze

  def skip_project_check?
    false
  end

  def can_cache_field?(field)
    true
  end

  attr_accessor :skip_markdown_cache_validation
  alias_method :skip_markdown_cache_validation?, :skip_markdown_cache_validation

  # Returns the default Banzai render context for the cached markdown field.
  def banzai_render_context(field)
    raise ArgumentError, "Unknown field: #{field.inspect}" unless
      cached_markdown_fields.key?(field)

    # Always include a project key, or Banzai complains
    project = self.project if self.respond_to?(:project)
    group   = self.group if self.respond_to?(:group)
    context = cached_markdown_fields[field].merge(project: project, group: group)

    # Banzai is less strict about authors, so don't always have an author key
    context[:author] = self.author if self.respond_to?(:author)

    context[:user] = self.parent_user if Feature.enabled?(:personal_snippet_reference_filters, context[:author])

    context
  end

  def rendered_field_content(markdown_field)
    return unless can_cache_field?(markdown_field)

    options = { skip_project_check: skip_project_check? }
    Banzai::Renderer.cacheless_render_field(self, markdown_field, options)
  end

  # Update every applicable column in a row if any one is invalidated, as we only store
  # one version per row
  def refresh_markdown_cache
    updates = cached_markdown_fields.markdown_fields.to_h do |markdown_field|
      [
        cached_markdown_fields.html_field(markdown_field),
        rendered_field_content(markdown_field)
      ]
    end

    updates['cached_markdown_version'] = latest_cached_markdown_version

    updates.each { |field, data| write_markdown_field(field, data) }
  end

  def refresh_markdown_cache!
    updates = refresh_markdown_cache
    if updates.present? && save_markdown(updates)
      # save_markdown updates DB columns directly, so compute and save mentions
      # by calling store_mentions! or we end-up with missing mentions although those
      # would appear in the notes, descriptions, etc in the UI
      store_mentions! if mentionable_attributes_changed?(updates)
    end
  end

  def cached_html_up_to_date?(markdown_field)
    return false if cached_html_for(markdown_field).nil? && __send__(markdown_field).present? # rubocop:disable GitlabSecurity/PublicSend

    html_field = cached_markdown_fields.html_field(markdown_field)

    markdown_changed = markdown_field_changed?(markdown_field)
    html_changed = markdown_field_changed?(html_field)

    latest_cached_markdown_version == cached_markdown_version &&
      (html_changed || markdown_changed == html_changed)
  end

  def invalidated_markdown_cache?
    cached_markdown_fields.html_fields.any? { |html_field| attribute_invalidated?(html_field) }
  end

  def attribute_invalidated?(attr)
    __send__("#{attr}_invalidated?") # rubocop:disable GitlabSecurity/PublicSend
  end

  def cached_html_for(markdown_field)
    raise ArgumentError, "Unknown field: #{markdown_field}" unless
      cached_markdown_fields.key?(markdown_field)

    __send__(cached_markdown_fields.html_field(markdown_field)) # rubocop:disable GitlabSecurity/PublicSend
  end

  # Updates the markdown cache if necessary, then returns the field
  # Unlike `cached_html_for` it returns `nil` if the field does not exist
  def updated_cached_html_for(markdown_field)
    return unless cached_markdown_fields.key?(markdown_field)

    if attribute_invalidated?(cached_markdown_fields.html_field(markdown_field))
      # Invalidated due to Markdown content change
      # We should not persist the updated HTML here since this will depend on whether the
      # Markdown content change will be persisted. Both will be persisted together when the model is saved.
      if changed_attributes.key?(markdown_field)
        refresh_markdown_cache
      else
        # Invalidated due to stale HTML cache
        # This could happen when the Markdown cache version is bumped
        # or when a model is imported and the HTML is empty.
        # We persist the updated HTML here so that subsequent calls
        # to this method do not have to regenerate the HTML again.
        refresh_markdown_cache!
      end
    end

    cached_html_for(markdown_field)
  end

  def latest_cached_markdown_version
    # because local_markdown_version is stored in application_settings which uses
    # cached_markdown_version too, we check explicitly to avoid an endless loop.
    local_version = local_markdown_version if respond_to?(:has_attribute?) && has_attribute?(:local_markdown_version)

    # rubocop:disable Gitlab/ModuleWithInstanceVariables -- acceptable use case
    # See https://docs.gitlab.com/ee/development/module_with_instance_variables.html#acceptable-use
    @latest_cached_markdown_version ||= Gitlab::MarkdownCache.latest_cached_markdown_version(
      local_version: local_version
    )
    # rubocop:enable Gitlab/ModuleWithInstanceVariables
  end

  def parent_user
    nil
  end

  def store_mentions!
    # We can only store mentions if the mentionable is a database object
    return unless self.is_a?(ApplicationRecord)

    identifier = user_mention_identifier

    # this may happen due to notes polymorphism, so noteable_id may point to a record
    # that no longer exists as we cannot have FK on noteable_id
    return if identifier.blank?

    refs = all_references(self.author)

    references = {}
    references[:mentioned_users_ids] = mentioned_filtered_user_ids_for(refs)
    references[:mentioned_groups_ids] = refs.mentioned_group_ids.presence
    references[:mentioned_projects_ids] = refs.mentioned_project_ids.presence

    if references.compact.any?
      user_mention_class.upsert(references.merge(identifier), unique_by: identifier.compact.keys)
    else
      user_mention_class.delete_by(identifier)
    end

    true
  end

  # Overriden on objects that needs to filter
  # mentioned users that cannot read them, for example,
  # guest users that are referenced on a confidential note.
  def mentioned_filtered_user_ids_for(refs)
    refs.mentioned_user_ids.presence
  end

  def mentionable_attributes_changed?(changes = saved_changes)
    return false unless is_a?(Mentionable)

    self.class.mentionable_attrs.any? do |attr|
      changes.key?(cached_markdown_fields.html_field(attr.first)) &&
        changes.fetch(cached_markdown_fields.html_field(attr.first)).last.present?
    end
  end

  def store_mentions_after_commit?
    false
  end

  included do
    cattr_reader :cached_markdown_fields do
      Gitlab::MarkdownCache::FieldData.new
    end

    if self < ActiveRecord::Base
      include Gitlab::MarkdownCache::ActiveRecord::Extension
    else
      prepend Gitlab::MarkdownCache::Redis::Extension
    end
  end

  class_methods do
    private

    # Specify that a field is markdown. Its rendered output will be cached in
    # a corresponding _html field. Any custom rendering options may be provided
    # as a context.
    def cache_markdown_field(markdown_field, context = {})
      cached_markdown_fields[markdown_field] = context

      html_field = cached_markdown_fields.html_field(markdown_field)
      invalidation_method = "#{html_field}_invalidated?".to_sym

      # The HTML becomes invalid if any dependent fields change. For now, assume
      # author and project invalidate the cache in all circumstances.
      define_method(invalidation_method) do
        return false if skip_markdown_cache_validation?

        changed_fields = changed_attributes.keys
        invalidations  = changed_fields & [markdown_field.to_s, *INVALIDATED_BY]
        !invalidations.empty? || !cached_html_up_to_date?(markdown_field)
      end
    end
  end
end

CacheMarkdownField.prepend_mod
