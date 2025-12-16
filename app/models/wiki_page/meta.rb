# frozen_string_literal: true

class WikiPage
  class Meta < ApplicationRecord
    include Gitlab::Utils::StrongMemoize
    include Mentionable
    include Noteable
    include Participable
    include Subscribable
    include Todoable

    self.table_name = 'wiki_page_meta'

    WikiPageInvalid = Class.new(ArgumentError)

    belongs_to :project, optional: true
    belongs_to :namespace, optional: true

    has_many :events, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent -- Technical debt
    has_many :slugs, class_name: 'WikiPage::Slug', foreign_key: 'wiki_page_meta_id', inverse_of: :wiki_page_meta
    has_many :notes, as: :noteable
    has_many :todos, as: :target
    has_many :user_mentions, class_name: 'Wikis::UserMention', foreign_key: 'wiki_page_meta_id',
      inverse_of: :wiki_page_meta

    validates :title, length: { maximum: 255 }, allow_nil: false
    validate :no_two_metarecords_in_same_container_can_have_same_canonical_slug
    validates_with ExactlyOnePresentValidator, fields: [:project_id, :namespace_id],
      message: ->(_fields) { s_('Wiki|WikiPage::Meta should belong to either project or namespace.') }

    participant :notes_with_associations

    scope :with_canonical_slug, ->(slug) do
      slug_table_name = klass.reflect_on_association(:slugs).table_name

      joins(:slugs).where(slug_table_name => { canonical: true, slug: slug })
    end
    scope :for_project, ->(project) do
      where(project: project)
    end

    delegate :wiki, to: :container
    delegate :to_reference, to: :wiki_page, allow_nil: true

    class << self
      # Return the (updated) WikiPage::Meta record for a given wiki page
      #
      # If none is found, then a new record is created, and its fields are set
      # to reflect the wiki_page passed.
      #
      # @param [String] last_known_slug
      # @param [WikiPage] wiki_page
      #
      # This method raises errors on validation issues.
      def find_or_create(last_known_slug, wiki_page)
        raise WikiPageInvalid unless wiki_page.valid?

        container = wiki_page.wiki.container
        known_slugs = [last_known_slug, wiki_page.slug].compact.uniq
        raise 'No slugs found! This should not be possible.' if known_slugs.empty?

        transaction do
          updates = wiki_page_updates(wiki_page)
          found = find_by_canonical_slug(known_slugs, container)
          meta = found || create!(updates.merge(container_attrs(container)))

          meta.update_state(found.nil?, known_slugs, wiki_page, updates)

          # We don't need to run validations here, since find_by_canonical_slug
          # guarantees that there is no conflict in canonical_slug, and DB
          # constraints on title and project_id/group_id enforce our other invariants
          # This saves us a query.
          meta
        end
      end

      def find_by_canonical_slug(canonical_slug, container)
        return unless canonical_slug.present? && container.present?

        meta, conflict = with_canonical_slug(canonical_slug)
          .where(container_attrs(container))
          .limit(2)

        if conflict.present?
          # Ensure the conflict record will be the orphaned record when doing a page update
          if canonical_slug.size > 1
            old_slug, _new_slug = canonical_slug

            meta, conflict = conflict, meta if conflict.canonical_slug == old_slug
          end

          transaction(requires_new: false) do
            conflict.todos.each_batch do |batch|
              batch.update_all(target_id: meta.id)
            end

            conflict.destroy
          end
        end

        meta
      end

      def declarative_policy_class
        'WikiPagePolicy'
      end

      private

      def wiki_page_updates(wiki_page)
        last_commit_date = wiki_page.version_commit_timestamp || Time.now.utc

        {
          title: wiki_page.title,
          created_at: last_commit_date,
          updated_at: last_commit_date
        }
      end

      def container_attrs(container)
        return { project_id: container.id } if container.is_a?(Project)

        { namespace_id: container.id } if container.is_a?(Namespace)
      end
    end

    def wiki_page
      wiki.find_page(canonical_slug, load_content: true)
    end

    def container
      project || namespace
    end

    def container=(value)
      self.project = value if value.is_a?(Project)
      self.namespace = value if value.is_a?(Namespace)
    end

    def resource_parent
      container
    end

    def for_group_wiki?
      namespace_id.present?
    end

    def container_key
      for_group_wiki? ? :namespace_id : :project_id
    end

    def canonical_slug
      slugs.canonical.take&.slug
    end
    strong_memoize_attr :canonical_slug

    def canonical_slug=(slug)
      return if @canonical_slug == slug

      if persisted?
        transaction do
          slugs.canonical.update_all(canonical: false)
          page_slug = slugs.create_with(canonical: true).find_or_create_by(slug: slug)
          page_slug.update_columns(canonical: true) unless page_slug.canonical?
        end
      else
        slugs.new(slug: slug, canonical: true)
      end

      @canonical_slug = slug
    end

    def update_state(created, known_slugs, wiki_page, updates)
      update_wiki_page_attributes(updates)
      insert_slugs(known_slugs, created, wiki_page.slug)
      self.canonical_slug = wiki_page.slug
    end

    def gfm_reference(from = nil)
      "#{container.class.name.downcase} wiki page #{to_reference(from)}"
    end

    def reference_link_text
      canonical_slug
    end

    # Used by app/policies/todo_policy.rb
    def readable_by?(user)
      Ability.allowed?(user, :read_wiki, self)
    end

    def to_ability_name
      'wiki_page'
    end

    def notes_with_associations
      notes.includes(:author)
    end

    def subscribed_without_subscriptions?(user, _project)
      participant?(user)
    end

    private

    def update_wiki_page_attributes(updates)
      # Remove all unnecessary updates:
      updates.delete(:updated_at) if updated_at == updates[:updated_at]
      updates.delete(:created_at) if created_at <= updates[:created_at]
      updates.delete(:title) if title == updates[:title]

      update_columns(updates) unless updates.empty?
    end

    def insert_slugs(strings, is_new, canonical_slug)
      creation = Time.current.utc

      slug_attrs = strings.map do |slug|
        slug_attributes(slug, canonical_slug, is_new, creation)
      end
      slugs.insert_all(slug_attrs) unless !is_new && slug_attrs.size == 1

      @canonical_slug = canonical_slug if is_new || strings.size == 1
    end

    def slug_attributes(slug, canonical_slug, is_new, creation)
      {
        slug: slug,
        canonical: is_new && slug == canonical_slug,
        created_at: creation,
        updated_at: creation
      }.merge(slug_meta_attributes)
    end

    def slug_meta_attributes
      { association(:slugs).reflection.foreign_key => id }
    end

    def no_two_metarecords_in_same_container_can_have_same_canonical_slug
      container_id = attributes[container_key.to_s]

      return unless container_id.present? && canonical_slug.present?

      offending = self.class.with_canonical_slug(canonical_slug).where(container_key => container_id)
      offending = offending.id_not_in(id) if persisted?

      return unless offending.exists?

      errors.add(:canonical_slug, 'each page in a wiki must have a distinct canonical slug')
    end
  end
end
