namespace :gitlab do
  namespace :assets do
    desc 'GitLab | Assets | Compile all frontend assets'
    task :compile do
      Rake::Task['assets:precompile'].invoke
      Rake::Task['webpack:compile'].invoke
      Rake::Task['gitlab:assets:fix_urls'].invoke
    end

    desc 'GitLab | Assets | Clean up old compiled frontend assets'
    task :clean do
      Rake::Task['assets:clean'].invoke
    end

    desc 'GitLab | Assets | Remove all compiled frontend assets'
    task :purge do
      Rake::Task['assets:clobber'].invoke
    end

    desc 'GitLab | Assets | Fix all absolute url references in CSS'
    task :fix_urls do
      css_files = Dir['public/assets/*.css']
      css_files.each do | file |
        # replace url(/assets/*) with url(./*)
        puts "Fixing #{file}"
        system "sed", "-i", "-e", 's/url(\([\"\']\?\)\/assets\//url(\1.\//g', file

        # rewrite the corresponding gzip file (if it exists)
        gzip = "#{file}.gz"
        if File.exist?(gzip)
          puts "Fixing #{gzip}"

          FileUtils.rm(gzip)
          mtime = File.stat(file).mtime

          File.open(gzip, 'wb+') do |f|
            gz = Zlib::GzipWriter.new(f, Zlib::BEST_COMPRESSION)
            gz.mtime = mtime
            gz.write IO.binread(file)
            gz.close

            File.utime(mtime, mtime, f.path)
          end
        end
      end
    end
  end
end
