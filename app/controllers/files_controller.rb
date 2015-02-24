class FilesController < ApplicationController
  skip_before_filter :authenticate_user!, :reject_blocked

  def download
    note = Note.find(params[:id])
    uploader = note.attachment

    if uploader.file_storage?
      if can?(current_user, :read_project, note.project)
        disposition = uploader.image? ? 'inline' : 'attachment'
        send_file uploader.file.path, disposition: disposition
      else
        not_found!
      end
    else
      redirect_to uploader.url
    end
  end
end
