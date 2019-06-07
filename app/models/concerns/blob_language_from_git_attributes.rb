# frozen_string_literal: true

# Applicable for blob classes with project attribute
module BlobLanguageFromGitAttributes
  extend ActiveSupport::Concern

  def language_from_gitattributes
    return unless project

    repository = project.repository
    repository.gitattribute(path, 'gitlab-language')
  end
end
