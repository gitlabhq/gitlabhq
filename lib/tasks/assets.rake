namespace :assets do
  desc 'GitLab | Assets | Fix Absolute URLs in CSS'
  task :precompile do
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
