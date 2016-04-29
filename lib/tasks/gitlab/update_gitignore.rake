namespace :gitlab do
  desc "GitLab | Update gitignore"
  task :update_gitignore do
    dir = File.expand_path('vendor', Rails.root)
    FileUtils.cd(dir)

    dir = File.expand_path('gitignore', dir)
    clone_gitignores(dir)
    remove_unneeded_files(dir)

    puts "Done".green
  end

  def clone_gitignores(dir)
    FileUtils.rm_rf(dir) if Dir.exist?(dir)
    system('git clone --depth=1 --branch=master https://github.com/github/gitignore.git')
  end

  def remove_unneeded_files(dir)
    [File.expand_path('Global', dir), dir].each do |path|
      Dir.entries(path).reject { |e| e =~ /(\.{1,2}|Global|\.gitignore)\z/ }.each do |file|
        FileUtils.rm_rf File.expand_path(file, path)
      end
    end
  end
end
