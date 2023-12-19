# frozen_string_literal: true

module DiffViewer
  class Image < Base
    include Rich
    include ClientSide

    self.partial_name = 'image'
    self.extensions = UploaderHelper::SAFE_IMAGE_EXT
    self.binary = true
    self.switcher_icon = 'doc-image'

    def self.switcher_title
      _('image diff')
    end

    def self.can_render?(diff_file, verify_binary: true)
      # When both blobs are missing, we often still have a textual diff that can
      # be displayed
      return false if diff_file.old_blob.nil? && diff_file.new_blob.nil?

      super
    end
  end
end
