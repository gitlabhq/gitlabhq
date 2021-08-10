# frozen_string_literal: true

module Packages
  class UpdatePackageFileService
    delegate :file, to: :@package_file

    def initialize(package_file, params)
      @package_file = package_file
      @params = params
    end

    def execute
      check_params

      return if same_as_params?

      # we need to access the file *before* updating the attributes linked to its path/key.
      file_storage_mode = file.file_storage?

      @package_file.package_id = package_id if package_id
      @package_file.file_name = file_name if file_name

      if file_storage_mode
        # package file is in mode LOCAL: we can pass the `file` to the update
        @package_file.file = file
      else
        # package file is in mode REMOTE: don't pass the `file` to the update
        # instead, pass the new file path. This will move the file
        # in object storage.
        @package_file.new_file_path = File.join(file.store_dir, @package_file.file_name)
      end

      @package_file.save!
    end

    private

    def check_params
      raise ArgumentError, 'package_file not persisted' unless @package_file.persisted?
      raise ArgumentError, 'package_id and file_name are blank' if package_id.blank? && file_name.blank?
    end

    def same_as_params?
      return false if package_id && package_id != @package_file.package_id
      return false if file_name && file_name != @package_file.file_name

      true
    end

    def package_id
      @params[:package_id]
    end

    def file_name
      @params[:file_name]
    end
  end
end
