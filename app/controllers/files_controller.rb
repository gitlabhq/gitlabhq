class FilesController < ApplicationController
  def download
    note = Note.find(params[:id])
    uploader = note.attachment

    if can?(current_user, :read_project, note.project)
      if uploader.file_storage?
        path = uploader.file.path.gsub("#{Rails.root}/public", Rails.root.to_s)

        if File.exist?(path)
          disposition = uploader.image? ? 'inline' : 'attachment'
          send_file path, disposition: disposition
        else
          not_found!
        end
      else
        redirect_to uploader.url
      end
    else
      not_found!
    end
  end
end
