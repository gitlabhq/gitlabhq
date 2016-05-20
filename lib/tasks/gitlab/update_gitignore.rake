namespace :gitlab do
  desc "GitLab | Update gitignore"
  task :update_gitignore do
    unless clone_gitignores
      puts "Cloning the gitignores failed".red
      return
    end

    remove_unneeded_files(gitignore_directory)
    remove_unneeded_files(global_directory)

    puts "Done".green
  end

  def clone_gitignores
    FileUtils.rm_rf(gitignore_directory) if Dir.exist?(gitignore_directory)
    FileUtils.cd vendor_directory

    system('git clone --depth=1 --branch=master https://github.com/github/gitignore.git')
  end

  # Retain only certain files:
  # - The LICENSE, because we have to
  # - The sub dir global
  # - The gitignores themself
  # - Dir.entires returns also the entries '.' and '..'
  def remove_unneeded_files(path)
    Dir.foreach(path) do |file|
      FileUtils.rm_rf(File.join(path, file)) unless file =~ /(\.{1,2}|LICENSE|Global|\.gitignore)\z/
    end
  end

  private

  def vendor_directory
    Rails.root.join('vendor')
  end

  def gitignore_directory
    File.join(vendor_directory, 'gitignore')
  end

  def global_directory
    File.join(gitignore_directory, 'Global')
  end
end
