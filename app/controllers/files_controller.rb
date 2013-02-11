class FilesController < ApplicationController
  def download
    uploader = Note.find(params[:id]).attachment
    uploader.retrieve_from_store!(params[:filename])
    send_file uploader.file.path, disposition: 'attachment'
  end
end

