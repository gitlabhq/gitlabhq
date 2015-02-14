class FilesController < ApplicationController
  def download
    note = Note.find(params[:id])
    uploader = note.attachment

    if uploader.file_storage?
      if can?(current_user, :read_project, note.project)
        # Replace old notes location in /public with the new one in / and send the file
        path = uploader.file.path.gsub("#{Rails.root}/public", Rails.root.to_s)

        disposition = uploader.image? ? 'inline' : 'attachment'
        send_file path, disposition: disposition
      else
        not_found!
      end
    else
      redirect_to uploader.url
    end
  end
end
