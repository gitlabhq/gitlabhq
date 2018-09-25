# frozen_string_literal: true

# Extra methods for uploader
module UploaderHelper
  include Gitlab::FileMarkdownLinkBuilder

  private

  def extension_match?(extensions)
    return false unless file

    extension = file.try(:extension) || File.extname(file.path).delete('.')
    extensions.include?(extension.downcase)
  end
end
