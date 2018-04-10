namespace :gitlab do
  desc "GitLab | Update templates"
  task :update_templates do
    TEMPLATE_DATA.each { |template| update(template) }
  end

  desc "GitLab | Update project templates"
  task :update_project_templates do
    if Rails.env.production?
      puts "This rake task is not meant fo production instances".red
      exit(1)
    end

    admin = User.find_by(admin: true)

    unless admin
      puts "No admin user could be found".red
      exit(1)
    end

    Gitlab::ProjectTemplate.all.each do |template|
      params = {
        import_url: template.clone_url,
        namespace_id: admin.namespace.id,
        path: template.name,
        skip_wiki: true
      }

      puts "Creating project for #{template.title}"
      project = Projects::CreateService.new(admin, params).execute

      unless project.persisted?
        puts project.errors.messages
        exit(1)
      end

      loop do
        if project.finished?
          puts "Import finished for #{template.name}"
          break
        end

        if project.failed?
          puts "Failed to import from #{project_params[:import_url]}".red
          exit(1)
        end

        puts "Waiting for the import to finish"

        sleep(5)
        project.reload
      end

      Projects::ImportExport::ExportService.new(project, admin).execute
      FileUtils.cp(project.export_project_path, template.archive_path)
      Projects::DestroyService.new(admin, project).execute
      puts "Exported #{template.name}".green
    end
    puts "Done".green
  end

  def update(template)
    sub_dir = template.repo_url.match(/([A-Za-z-]+)\.git\z/)[1]
    dir = File.join(vendor_directory, sub_dir)

    unless clone_repository(template.repo_url, dir)
      puts "Cloning the #{sub_dir} templates failed".red
      return
    end

    remove_unneeded_files(dir, template.cleanup_regex)
    puts "Done".green
  end

  def clone_repository(url, directory)
    FileUtils.rm_rf(directory) if Dir.exist?(directory)

    system("git clone #{url} --depth=1 --branch=master #{directory}")
  end

  # Retain only certain files:
  # - The LICENSE, because we have to
  # - The sub dirs so we can organise the file by category
  # - The templates themself
  # - Dir.entries returns also the entries '.' and '..'
  def remove_unneeded_files(directory, regex)
    Dir.foreach(directory) do |file|
      FileUtils.rm_rf(File.join(directory, file)) unless file =~ regex
    end
  end

  private

  Template = Struct.new(:repo_url, :cleanup_regex)
  TEMPLATE_DATA = [
    Template.new(
      "https://github.com/github/gitignore.git",
      /(\.{1,2}|LICENSE|Global|\.gitignore)\z/
    ),
    Template.new(
      "https://gitlab.com/gitlab-org/gitlab-ci-yml.git",
      /(\.{1,2}|LICENSE|CONTRIBUTING.md|Pages|autodeploy|\.gitlab-ci.yml)\z/
    ),
    Template.new(
      "https://gitlab.com/gitlab-org/Dockerfile.git",
      /(\.{1,2}|LICENSE|CONTRIBUTING.md|\.Dockerfile)\z/
    )
  ].freeze

  def vendor_directory
    Rails.root.join('vendor')
  end
end
