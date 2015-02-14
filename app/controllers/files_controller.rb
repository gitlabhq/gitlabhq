class FilesController < ApplicationController
  def download_notes
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
      not_found!
    end
  end

  def download_files
    namespace_id = params[:namespace]
    project_id = params[:project]
    folder_id = params[:folder_id]
    filename = params[:filename]
    project_with_namespace="#{namespace_id}/#{project_id}"
    filename_with_id="#{folder_id}/#{filename}"
    
    project = Project.find_with_namespace(project_with_namespace)

    uploader = FileUploader.new("#{Rails.root}/uploads","#{project_with_namespace}/#{folder_id}")
    uploader.retrieve_from_store!(filename)

    if can?(current_user, :read_project, project)
      download(uploader)
    else
      not_found!
    end
  end

  def download(uploader)
    disposition = uploader.image? ? 'inline' : 'attachment'
    send_file uploader.file.path, disposition: disposition
  end
end
