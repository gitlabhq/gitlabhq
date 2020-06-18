# frozen_string_literal: true

class UploaderFinder
  # Instantiates a a new FileUploader
  # FileUploader can be opened via .open agnostic of storage type
  # Arguments correspond to Upload.secret, Upload.model_type and Upload.file_path
  # Returns a FileUploader with uploaded file retrieved into the object state
  def initialize(project, secret, file_path)
    @project = project
    @secret = secret
    @file_path = file_path
  end

  def execute
    prevent_path_traversal_attack!
    retrieve_file_state!

    uploader
  rescue ::Gitlab::Utils::PathTraversalAttackError
    nil # no-op if for incorrect files
  end

  def prevent_path_traversal_attack!
    Gitlab::Utils.check_path_traversal!(@file_path)
  end

  def retrieve_file_state!
    uploader.retrieve_from_store!(@file_path)
  end

  def uploader
    @uploader ||= FileUploader.new(@project, secret: @secret)
  end
end
