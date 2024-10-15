# frozen_string_literal: true

class WikiPage
  class Meta < ApplicationRecord
    include HasWikiPageMetaAttributes
    include Mentionable
    include Noteable

    self.table_name = 'wiki_page_meta'

    belongs_to :project, optional: true
    belongs_to :namespace, optional: true

    has_many :slugs, class_name: 'WikiPage::Slug', foreign_key: 'wiki_page_meta_id', inverse_of: :wiki_page_meta
    has_many :notes, as: :noteable
    has_many :user_mentions, class_name: 'Wikis::UserMention', foreign_key: 'wiki_page_meta_id',
      inverse_of: :wiki_page_meta

    validate :project_or_namespace_present?

    alias_method :resource_parent, :project

    def container
      project || namespace
    end

    def container=(value)
      self.project = value if value.is_a?(Project)
      self.namespace = value if value.is_a?(Namespace)
    end

    def for_group_wiki?
      namespace_id.present?
    end

    def container_key
      for_group_wiki? ? :namespace_id : :project_id
    end

    private

    def project_or_namespace_present?
      return unless (project_id.nil? && namespace_id.nil?) || (project_id.present? && namespace_id.present?)

      errors.add(:base, s_('Wiki|WikiPage::Meta should belong to either project or namespace.'))
    end
  end
end
