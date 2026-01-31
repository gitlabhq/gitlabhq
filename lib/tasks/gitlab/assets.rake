# frozen_string_literal: true

namespace :gitlab do
  namespace :assets do
    task :tailwind, [:silent] do |_t, args|
      cmd = 'yarn tailwindcss:build && yarn tailwindcss:cqs:build'
      cmd += '> /dev/null 2>&1' if args[:silent].present?

      abort Rainbow('Error: Unable to build Tailwind CSS bundle.').red unless system(cmd)
    end

    desc 'GitLab | Assets | Compile all frontend assets'
    task compile: :tailwind do
      require 'fileutils'

      require_dependency 'gitlab/task_helpers'
      require_relative '../../../scripts/lib/assets_sha'

      cached_assets_sha = AssetsSha.cached_assets_sha256
      current_assets_sha = AssetsSha.sha256_of_assets_impacting_compilation

      puts "Cached Assets SHA256: #{cached_assets_sha}"
      puts "Current Assets SHA256: #{current_assets_sha}"

      if current_assets_sha != cached_assets_sha
        FileUtils.rm_rf([AssetsSha::PUBLIC_ASSETS_DIR] + Dir.glob('app/assets/javascripts/locale/**/app.js'))

        # gettext:compile needs to run before rake:assets:precompile because
        # app/assets/javascripts/locale/**/app.js are pre-compiled by Sprockets
        Gitlab::TaskHelpers.invoke_and_time_task('gettext:compile')
        # Skip Yarn Install when using Cssbundling
        Rake::Task["css:install"].clear
        Gitlab::TaskHelpers.invoke_and_time_task('rake:assets:precompile')

        log_path = ENV['WEBPACK_COMPILE_LOG_PATH']

        cmd = 'yarn webpack'
        cmd += " > #{log_path} 2>&1" if log_path

        log_path_message = ""

        if log_path
          puts "Compiling frontend assets with webpack, running: #{cmd}"

          log_path_message += "\nWritten webpack log written to #{log_path}"

          if ENV['CI_JOB_URL']
            log_path_message += "\nYou can inspect the webpack full log here:"
            log_path_message += "#{ENV['CI_JOB_URL']}/artifacts/file/#{log_path}"
          end
        end

        ENV['NODE_OPTIONS'] = '--max-old-space-size=8192' if ENV.has_key?('CI')
        if ENV['GITLAB_LARGE_RUNNER_OPTIONAL'] == "saas-linux-large-amd64"
          ENV['NODE_OPTIONS'] = '--max-old-space-size=16384'
        end

        # Set Sidekiq gem information for webpack
        require 'bundler'
        require 'sidekiq'
        sidekiq_spec = Bundler.load.specs.find { |spec| spec.name == 'sidekiq' }

        abort Rainbow('Unable to find Sidekiq in Gemfile!').red unless sidekiq_spec

        ENV['SIDEKIQ_ASSETS_SRC_PATH'] = File.join(sidekiq_spec.full_gem_path, "web", "assets")
        ENV['SIDEKIQ_ASSETS_DEST_PATH'] = File.join(AssetsSha::PUBLIC_ASSETS_DIR, "sidekiq")

        unless system(cmd)
          puts Rainbow('Error: Unable to compile webpack production bundle.').red

          if log_path
            puts "Last 100 line of webpack log:"
            system("tail -n 100 #{log_path}")
          end

          puts Rainbow(log_path_message).yellow unless log_path_message.empty?
          abort
        end

        puts log_path_message unless log_path_message.empty?

        Gitlab::TaskHelpers.invoke_and_time_task('gitlab:assets:fix_urls')
        Gitlab::TaskHelpers.invoke_and_time_task('gitlab:assets:check_page_bundle_mixins_css_for_sideeffects')
      end
    end

    desc 'GitLab | Assets | Clean up old compiled frontend assets'
    task clean: ['rake:assets:clean']

    desc 'GitLab | Assets | Remove all compiled frontend assets'
    task purge: ['rake:assets:clobber']

    desc 'GitLab | Assets | Uninstall frontend dependencies'
    task purge_modules: ['yarn:clobber']

    desc 'GitLab | Assets | Fix all absolute url references in CSS'
    task :fix_urls do
      css_files = Dir['public/assets/*.css']
      css_files.each do |file|
        # replace url(/assets/*) with url(./*)
        puts "Fixing #{file}"
        system "sed", "-i", "-e", 's/url(\([\"\']\?\)\/assets\//url(\1.\//g', file

        # rewrite the corresponding gzip file (if it exists)
        gzip = "#{file}.gz"
        next unless File.exist?(gzip)

        puts "Fixing #{gzip}"

        FileUtils.rm(gzip)
        mtime = File.stat(file).mtime

        File.open(gzip, 'wb+') do |f|
          gz = Zlib::GzipWriter.new(f, Zlib::BEST_COMPRESSION)
          gz.mtime = mtime
          gz.write File.binread(file)
          gz.close

          File.utime(mtime, mtime, f.path)
        end
      end
    end

    desc 'GitLab | Assets | Compile vendor assets'
    task :vendor do
      abort Rainbow('Error: Unable to compile webpack DLL.').red unless system('yarn webpack-vendor')
    end

    desc 'GitLab | Assets | Check that scss mixins do not introduce any sideffects'
    task :check_page_bundle_mixins_css_for_sideeffects do
      unless system('./scripts/frontend/check_page_bundle_mixins_css_for_sideeffects.js')
        abort Rainbow('Error: At least one CSS changes introduces an unwanted sideeffect').red
      end
    end
  end
end
