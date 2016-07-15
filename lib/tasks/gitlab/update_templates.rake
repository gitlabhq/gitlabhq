namespace :gitlab do
  desc "GitLab | Update templates"
  task :update_templates do
    TEMPLATE_DATA.each { |template| update(template) }
  end

  def update(template)
    sub_dir = template.repo_url.match(/([a-z-]+)\.git\z/)[1]
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
      /(\.{1,2}|LICENSE|Pages|\.gitlab-ci.yml)\z/
    )
  ]

  def vendor_directory
    Rails.root.join('vendor')
  end
end
