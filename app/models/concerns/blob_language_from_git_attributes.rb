# frozen_string_literal: true

module BlobLanguageFromGitAttributes
  extend ActiveSupport::Concern

  def language_from_gitattributes
    return unless repository&.exists?

    repository.gitattribute(path, 'gitlab-language')
  end
end
