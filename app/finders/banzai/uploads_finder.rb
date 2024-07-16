# frozen_string_literal: true

module Banzai
  class UploadsFinder
    include FinderMethods

    def initialize(parent:)
      @parent = parent
    end

    def execute
      Upload
        .for_model_type_and_id(@parent.class.polymorphic_name, @parent.id)
        .for_uploader(uploader_class)
        .order_by_created_at_desc
    end

    def find_by_secret_and_filename(secret, filename)
      return unless secret && filename

      uploader = uploader_class.new(@parent, secret: secret)
      upload_paths = uploader.upload_paths(filename)

      execute.without_order.find_by_path(upload_paths)
    rescue FileUploader::InvalidSecret
      nil
    end

    private

    def uploader_class
      case @parent
      when Group
        NamespaceFileUploader
      when Project
        FileUploader
      else
        raise ArgumentError, "unknown uploader for #{@parent.class.name}"
      end
    end
  end
end
