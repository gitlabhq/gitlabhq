# frozen_string_literal: true

class FileMover
  include Gitlab::Utils::StrongMemoize

  attr_reader :secret, :file_name, :from_model, :to_model, :update_field

  def initialize(file_path, update_field = :description, from_model:, to_model:)
    @secret = File.split(File.dirname(file_path)).last
    @file_name = File.basename(file_path)
    @from_model = from_model
    @to_model = to_model
    @update_field = update_field
  end

  def execute
    temp_file_uploader.retrieve_from_store!(file_name)

    return unless valid?

    uploader.retrieve_from_store!(file_name)

    move

    if update_markdown
      update_upload_model
    end
  end

  private

  def valid?
    if temp_file_uploader.file_storage?
      Pathname.new(temp_file_path).realpath.to_path.start_with?(
        (Pathname(temp_file_uploader.root) + temp_file_uploader.base_dir).to_path
      )
    else
      temp_file_uploader.exists?
    end
  end

  def move
    if temp_file_uploader.file_storage?
      FileUtils.mkdir_p(File.dirname(file_path))
      FileUtils.move(temp_file_path, file_path)
    else
      uploader.copy_file(temp_file_uploader.file)
      temp_file_uploader.upload.destroy!
    end
  end

  def update_markdown
    updated_text = to_model.read_attribute(update_field)
                           .gsub(temp_file_uploader.markdown_link, uploader.markdown_link)
    to_model.update_attribute(update_field, updated_text)
  rescue StandardError
    revert
    false
  end

  def update_upload_model
    return unless upload = temp_file_uploader.upload
    return if upload.destroyed?

    upload.update!(model: to_model)
  end

  def temp_file_path
    strong_memoize(:temp_file_path) do
      temp_file_uploader.file.path
    end
  end

  def file_path
    strong_memoize(:file_path) do
      uploader.file.path
    end
  end

  def uploader
    @uploader ||=
      begin
        uploader = PersonalFileUploader.new(to_model, secret: secret)

        # Enforcing a REMOTE object storage given FileUploader#retrieve_from_store! won't do it
        # (there's no upload at the target yet).
        if uploader.class.object_store_enabled?
          uploader.object_store = ::ObjectStorage::Store::REMOTE
        end

        uploader
      end
  end

  def temp_file_uploader
    @temp_file_uploader ||= PersonalFileUploader.new(from_model, secret: secret)
  end

  def revert
    Gitlab::AppLogger.warn("Markdown not updated, file move reverted for #{to_model}")

    if temp_file_uploader.file_storage?
      FileUtils.move(file_path, temp_file_path)
    end
  end
end
