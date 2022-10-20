# frozen_string_literal: true

module HasWiki
  extend ActiveSupport::Concern

  included do
    validate :check_wiki_path_conflict
  end

  def create_wiki
    wiki.create_wiki_repository
    true
  rescue Wiki::CouldNotCreateWikiError
    errors.add(:base, _('Failed to create wiki'))
    false
  end

  def wiki
    strong_memoize(:wiki) do
      Wiki.for_container(self, self.first_owner)
    end
  end

  def wiki_repository_exists?
    wiki.repository_exists?
  end

  private

  def check_wiki_path_conflict
    return if path.blank?

    path_to_check = path.ends_with?('.wiki') ? path.chomp('.wiki') : "#{path}.wiki"

    if Project.in_namespace(parent_id).where(path: path_to_check).exists? ||
        GroupsFinder.new(nil, parent: parent_id).execute.where(path: path_to_check).exists?
      errors.add(:name, _('has already been taken'))
    end
  end
end
