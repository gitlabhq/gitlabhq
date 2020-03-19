# frozen_string_literal: true

class WikiPage
  class Meta < ApplicationRecord
    include Gitlab::Utils::StrongMemoize

    CanonicalSlugConflictError = Class.new(ActiveRecord::RecordInvalid)

    self.table_name = 'wiki_page_meta'

    belongs_to :project

    has_many :slugs, class_name: 'WikiPage::Slug', foreign_key: 'wiki_page_meta_id', inverse_of: :wiki_page_meta
    has_many :events, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

    validates :title, presence: true
    validates :project_id, presence: true
    validate :no_two_metarecords_in_same_project_can_have_same_canonical_slug

    scope :with_canonical_slug, ->(slug) do
      joins(:slugs).where(wiki_page_slugs: { canonical: true, slug: slug })
    end

    alias_method :resource_parent, :project

    # Return the (updated) WikiPage::Meta record for a given wiki page
    #
    # If none is found, then a new record is created, and its fields are set
    # to reflect the wiki_page passed.
    #
    # @param [String] last_known_slug
    # @param [WikiPage] wiki_page
    #
    # As with all `find_or_create` methods, this one raises errors on
    # validation issues.
    def self.find_or_create(last_known_slug, wiki_page)
      project = wiki_page.wiki.project
      known_slugs = [last_known_slug, wiki_page.slug].compact.uniq
      raise 'no slugs!' if known_slugs.empty?

      transaction do
        found = find_by_canonical_slug(known_slugs, project)
        meta = found || create(title: wiki_page.title, project_id: project.id)

        meta.update_state(found.nil?, known_slugs, wiki_page)

        # We don't need to run validations here, since find_by_canonical_slug
        # guarantees that there is no conflict in canonical_slug, and DB
        # constraints on title and project_id enforce our other invariants
        # This saves us a query.
        meta
      end
    end

    def self.find_by_canonical_slug(canonical_slug, project)
      meta, conflict = with_canonical_slug(canonical_slug)
        .where(project_id: project.id)
        .limit(2)

      if conflict.present?
        meta.errors.add(:canonical_slug, 'Duplicate value found')
        raise CanonicalSlugConflictError.new(meta)
      end

      meta
    end

    def canonical_slug
      strong_memoize(:canonical_slug) { slugs.canonical.first&.slug }
    end

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

    def update_state(created, known_slugs, wiki_page)
      update_wiki_page_attributes(wiki_page)
      insert_slugs(known_slugs, created, wiki_page.slug)
      self.canonical_slug = wiki_page.slug
    end

    def update_columns(attrs = {})
      super(attrs.reverse_merge(updated_at: Time.now.utc))
    end

    def self.update_all(attrs = {})
      super(attrs.reverse_merge(updated_at: Time.now.utc))
    end

    private

    def update_wiki_page_attributes(page)
      update_columns(title: page.title) unless page.title == title
    end

    def insert_slugs(strings, is_new, canonical_slug)
      creation = Time.now.utc

      slug_attrs = strings.map do |slug|
        {
          wiki_page_meta_id: id,
          slug: slug,
          canonical: (is_new && slug == canonical_slug),
          created_at: creation,
          updated_at: creation
        }
      end
      slugs.insert_all(slug_attrs) unless !is_new && slug_attrs.size == 1

      @canonical_slug = canonical_slug if is_new || strings.size == 1
    end

    def no_two_metarecords_in_same_project_can_have_same_canonical_slug
      return unless project_id.present? && canonical_slug.present?

      offending = self.class.with_canonical_slug(canonical_slug).where(project_id: project_id)
      offending = offending.where.not(id: id) if persisted?

      if offending.exists?
        errors.add(:canonical_slug, 'each page in a wiki must have a distinct canonical slug')
      end
    end
  end
end
