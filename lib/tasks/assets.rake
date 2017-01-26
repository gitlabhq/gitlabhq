namespace :assets do
  desc 'GitLab | Assets | Fix Absolute URLs in CSS'
  task :precompile do
    css_files = Dir['public/assets/*.css']
    css_files.each do | file |
      puts "Fixing #{file}"
      system "sed", "-i", "-e", 's/url(\([\"\']\?\)\/assets\//url(\1.\//g', file
    end
  end
end
