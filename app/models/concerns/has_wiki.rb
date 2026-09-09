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

    # Use a direct `Group.where` rather than `GroupsFinder`: the finder's
    # `by_parent` no-ops on nil parents (broadening to all visible groups) and
    # its visibility filter would miss private siblings. A path collision is
    # structural and must ignore both.
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/599240
    if Project.in_namespace(parent_id).where(path: path_to_check).exists? ||
        Group.where(parent_id: parent_id, path: path_to_check).exists?
      errors.add(:name, _('has already been taken'))
    end
  end
end
