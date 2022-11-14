# frozen_string_literal: true

module Projects
  class WikiRepository < ApplicationRecord
    self.table_name = :project_wiki_repositories

    belongs_to :project, inverse_of: :wiki_repository

    validates :project, presence: true, uniqueness: true
  end
end

Projects::WikiRepository.prepend_mod_with('Projects::WikiRepository')
