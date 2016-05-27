namespace :gitlab do
  desc "GitLab | Update templates"
  task :update_templates do
    update("gitignore")
    update("gitlab-ci-yml")
  end

  def update(directory)
    unless clone_repository(directory)
      puts "Cloning the #{directory} templates failed".red
      return
    end

    remove_unneeded_files(directory)
    puts "Done".green
  end

  def clone_repository(directory)
    dir = File.join(vendor_directory, directory)
    FileUtils.rm_rf(dir) if Dir.exist?(dir)
    FileUtils.cd vendor_directory

    system("git clone --depth=1 --branch=master #{TEMPLATE_DATA[directory]}")
  end

  # Retain only certain files:
  # - The LICENSE, because we have to
  # - The sub dir global
  # - The gitignores themself
  # - Dir.entires returns also the entries '.' and '..'
  def remove_unneeded_files(directory)
    regex = CLEANUP_REGEX[directory]
    Dir.foreach(directory) do |file|
      FileUtils.rm_rf(File.join(directory, file)) unless file =~ regex
    end
  end

  private

  TEMPLATE_DATA = {
      "gitignore" => "https://github.com/github/gitignore.git",
      "gitlab-ci-yml" => "https://gitlab.com/gitlab-org/gitlab-ci-yml.git"
  }.freeze

  CLEANUP_REGEX = {
    "gitignore" => /(\.{1,2}|LICENSE|Global|\.gitignore)\z/,
    "gitlab-ci-yml" => /(\.{1,2}|LICENSE|Pages|\.gitignore)\z/
  }.freeze

  def vendor_directory
    Rails.root.join('vendor')
  end

  def gitignore_directory
    File.join(vendor_directory, 'gitignore')
  end

  def gitlab_ci_directory
    File.join(vendor_directory, 'gitlab-ci')
  end
end
