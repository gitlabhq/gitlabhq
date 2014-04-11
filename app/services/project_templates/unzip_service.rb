require 'zip'

class ProjectTemplateUnzipService

  attr_accessor :project_template

  def execute(project_template_id)
    @project_template = ProjectTemplate.find_by_id(project_template_id)

    if !@project_template.nil? && @project_template.state == 0
      unzip_file_contents
    end
  end

  private

  def unzip_file_contents
    path = File.join(@project_template.template_path,@project_template.upload.file.filename)

    Zip::ZipFile.open(path) do |zip_file|
      zip_file.each do |f|
        extract_path = File.join(@project_template.template_path, f.name)
        zip_file.extract(f, extract_path) unless File.exist?(extract_path)
      end
    end

    # delete uploaded zip file
    @project_template.remove_upload!
    # set state to success
    @project_template.state = 1
    # save project with disabled validation (because we're clearing the 'upload' model field)
    @project_template.save(:validate => false)

  end

end
