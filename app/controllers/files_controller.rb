class FilesController < ApplicationController
  def download
    uploader = Note.find(params[:id]).attachment
    send_file uploader.file.path, disposition: 'attachment'
  end
end

