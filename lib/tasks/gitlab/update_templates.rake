namespace :gitlab do
  desc "GitLab | Update templates"
  task :update_templates do
    TEMPLATE_DATA.each { |template| update(template) }
  end

  desc "GitLab | Update project templates"
  task :update_project_templates, [] => :environment do |_task, args|
    # we need an instance method from Gitlab::ImportExport::CommandLineUtil and don't
    # want to include it in the task, as this would affect subsequent tasks as well
    downloader = Class.new do
      extend Gitlab::ImportExport::CommandLineUtil

      def self.call(uploader, upload_path)
        download_or_copy_upload(uploader, upload_path)
      end
    end

    template_names = args.extras.to_set

    if Rails.env.production?
      raise "This rake task is not meant for production instances"
    end

    admin = User.find_by(admin: true)

    unless admin
      raise "No admin user could be found"
    end

    tmp_namespace_path = "tmp-project-import-#{Time.now.to_i}"
    puts "Creating temporary namespace #{tmp_namespace_path}"
    tmp_namespace = Namespace.create!(owner: admin, name: tmp_namespace_path, path: tmp_namespace_path)

    templates = if template_names.empty?
                  Gitlab::ProjectTemplate.all
                else
                  Gitlab::ProjectTemplate.all.select { |template| template_names.include?(template.name) }
                end

    templates.each do |template|
      params = {
        import_url: template.clone_url,
        namespace_id: tmp_namespace.id,
        path: template.name,
        skip_wiki: true
      }

      puts "Creating project for #{template.title}"
      project = Projects::CreateService.new(admin, params).execute

      unless project.persisted?
        raise "Failed to create project: #{project.errors.messages}"
      end

      loop do
        if project.import_finished?
          puts "Import finished for #{template.name}"
          break
        end

        if project.import_failed?
          raise "Failed to import from #{project_params[:import_url]}"
        end

        puts "Waiting for the import to finish"

        sleep(5)
        project.reset
      end

      Projects::ImportExport::ExportService.new(project, admin).execute
      downloader.call(project.export_file, template.archive_path)

      unless Projects::DestroyService.new(project, admin).execute
        puts "Failed to destroy project #{template.name} (but namespace will be cleaned up later)"
      end

      puts "Exported #{template.name}".green
    end

    success = true
  ensure
    if tmp_namespace
      puts "Destroying temporary namespace #{tmp_namespace_path}"
      tmp_namespace.destroy
    end

    puts "Done".green if success
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
      "https://gitlab.com/gitlab-org/Dockerfile.git",
      /(\.{1,2}|LICENSE|CONTRIBUTING.md|\.Dockerfile)\z/
    )
  ].freeze

  def vendor_directory
    Rails.root.join('vendor')
  end
end
