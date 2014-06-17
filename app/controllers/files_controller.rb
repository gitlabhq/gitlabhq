class FilesController < ApplicationController
  def download
    note = Note.find(params[:id])
    uploader = note.attachment

    if uploader.file_storage?
      if can?(current_user, :read_project, note.project)
        send_file uploader.file.path, disposition: 'attachment'
      else
        not_found!
      end
    else
      redirect_to uploader.url
    end
  end
end
