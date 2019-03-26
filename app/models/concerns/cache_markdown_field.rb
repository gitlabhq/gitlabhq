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

  # Increment this number every time the renderer changes its output
  CACHE_COMMONMARK_VERSION_START  = 10
  CACHE_COMMONMARK_VERSION        = 15

  # changes to these attributes cause the cache to be invalidates
  INVALIDATED_BY = %w[author project].freeze

  # Knows about the relationship between markdown and html field names, and
  # stores the rendering contexts for the latter
  class FieldData
    def initialize
      @data = {}
    end

    delegate :[], :[]=, to: :@data

    def markdown_fields
      @data.keys
    end

    def html_field(markdown_field)
      "#{markdown_field}_html"
    end

    def html_fields
      markdown_fields.map { |field| html_field(field) }
    end

    def html_fields_whitelisted
      markdown_fields.each_with_object([]) do |field, fields|
        if @data[field].fetch(:whitelisted, false)
          fields << html_field(field)
        end
      end
    end
  end

  def skip_project_check?
    false
  end

  # Returns the default Banzai render context for the cached markdown field.
  def banzai_render_context(field)
    raise ArgumentError.new("Unknown field: #{field.inspect}") unless
      cached_markdown_fields.markdown_fields.include?(field)

    # Always include a project key, or Banzai complains
    project = self.project if self.respond_to?(:project)
    group   = self.group if self.respond_to?(:group)
    context = cached_markdown_fields[field].merge(project: project, group: group)

    # Banzai is less strict about authors, so don't always have an author key
    context[:author] = self.author if self.respond_to?(:author)

    context[:markdown_engine] = :common_mark

    context
  end

  # Update every column in a row if any one is invalidated, as we only store
  # one version per row
  def refresh_markdown_cache
    options = { skip_project_check: skip_project_check? }

    updates = cached_markdown_fields.markdown_fields.map do |markdown_field|
      [
        cached_markdown_fields.html_field(markdown_field),
        Banzai::Renderer.cacheless_render_field(self, markdown_field, options)
      ]
    end.to_h
    updates['cached_markdown_version'] = latest_cached_markdown_version

    updates.each {|html_field, data| write_attribute(html_field, data) }
  end

  def refresh_markdown_cache!
    updates = refresh_markdown_cache

    return unless persisted? && Gitlab::Database.read_write?

    update_columns(updates)
  end

  def cached_html_up_to_date?(markdown_field)
    html_field = cached_markdown_fields.html_field(markdown_field)

    return false if cached_html_for(markdown_field).nil? && !__send__(markdown_field).nil? # rubocop:disable GitlabSecurity/PublicSend

    markdown_changed = attribute_changed?(markdown_field) || false
    html_changed = attribute_changed?(html_field) || false

    latest_cached_markdown_version == cached_markdown_version &&
      (html_changed || markdown_changed == html_changed)
  end

  def invalidated_markdown_cache?
    cached_markdown_fields.html_fields.any? {|html_field| attribute_invalidated?(html_field) }
  end

  def attribute_invalidated?(attr)
    __send__("#{attr}_invalidated?") # rubocop:disable GitlabSecurity/PublicSend
  end

  def cached_html_for(markdown_field)
    raise ArgumentError.new("Unknown field: #{field}") unless
      cached_markdown_fields.markdown_fields.include?(markdown_field)

    __send__(cached_markdown_fields.html_field(markdown_field)) # rubocop:disable GitlabSecurity/PublicSend
  end

  def latest_cached_markdown_version
    @latest_cached_markdown_version ||= (CacheMarkdownField::CACHE_COMMONMARK_VERSION << 16) | local_version
  end

  def local_version
    # because local_markdown_version is stored in application_settings which
    # uses cached_markdown_version too, we check explicitly to avoid
    # endless loop
    return local_markdown_version if has_attribute?(:local_markdown_version)

    settings = Gitlab::CurrentSettings.current_application_settings

    # Following migrations are not properly isolated and
    # use real models (by calling .ghost method), in these migrations
    # local_markdown_version attribute doesn't exist yet, so we
    # use a default value:
    # db/migrate/20170825104051_migrate_issues_to_ghost_user.rb
    # db/migrate/20171114150259_merge_requests_author_id_foreign_key.rb
    if settings.respond_to?(:local_markdown_version)
      settings.local_markdown_version
    else
      0
    end
  end

  included do
    cattr_reader :cached_markdown_fields do
      FieldData.new
    end

    # Always exclude _html fields from attributes (including serialization).
    # They contain unredacted HTML, which would be a security issue
    alias_method :attributes_before_markdown_cache, :attributes
    def attributes
      attrs = attributes_before_markdown_cache
      html_fields = cached_markdown_fields.html_fields
      whitelisted = cached_markdown_fields.html_fields_whitelisted
      exclude_fields = html_fields - whitelisted

      exclude_fields.each do |field|
        attrs.delete(field)
      end

      if whitelisted.empty?
        attrs.delete('cached_markdown_version')
      end

      attrs
    end

    # Using before_update here conflicts with elasticsearch-model somehow
    before_create :refresh_markdown_cache, if: :invalidated_markdown_cache?
    before_update :refresh_markdown_cache, if: :invalidated_markdown_cache?
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
        changed_fields = changed_attributes.keys
        invalidations  = changed_fields & [markdown_field.to_s, *INVALIDATED_BY]
        invalidations.delete(markdown_field.to_s) if changed_fields.include?("#{markdown_field}_html")

        !invalidations.empty? || !cached_html_up_to_date?(markdown_field)
      end
    end
  end
end
