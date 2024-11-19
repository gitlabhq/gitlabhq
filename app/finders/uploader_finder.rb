# frozen_string_literal: true

class UploaderFinder
  # Instantiates a new FileUploader or NamespaceFileUploader based on container type
  # FileUploader can be opened via .open agnostic of storage type
  # Arguments correspond to Upload.secret, Upload.model_type and Upload.file_path
  # Returns a FileUploader with uploaded file retrieved into the object state
  #
  # container - project, project namespace or group
  # secret - secret string in path to the file, based on FileUploader::MARKDOWN_PATTERN regex
  # file_path - relative path to the file based on FileUploader::MARKDOWN_PATTERN regex
  def initialize(container, secret, file_path)
    @container = container
    @secret = secret
    @file_path = file_path
  end

  def execute
    prevent_path_traversal_attack!
    retrieve_file_state!

    uploader
  rescue ::Gitlab::PathTraversal::PathTraversalAttackError
    nil # no-op if for incorrect files
  end

  private

  def prevent_path_traversal_attack!
    Gitlab::PathTraversal.check_path_traversal!(@file_path)
  end

  def retrieve_file_state!
    uploader.retrieve_from_store!(@file_path)
  end

  def uploader
    @uploader ||= uploader_klass.new(@container, secret: @secret)
  end

  def uploader_klass
    @container.is_a?(Group) ? NamespaceFileUploader : FileUploader
  end
end
