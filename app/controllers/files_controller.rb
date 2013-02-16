class FilesController < ApplicationController
  def download
    note = Note.find(params[:id])

    if can?(current_user, :read_project, note.project)
      uploader = note.attachment
      send_file uploader.file.path, disposition: 'attachment'
    else
      not_found!
    end
  end
end

