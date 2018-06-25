require "gettext_i18n_rails/tasks"

namespace :gettext do
  # Customize list of translatable files
  # See: https://github.com/grosser/gettext_i18n_rails#customizing-list-of-translatable-files
  def files_to_translate
    folders = %W(ee app lib config #{locale_path}).join(',')
    exts = %w(rb erb haml slim rhtml js jsx vue handlebars hbs mustache).join(',')

    Dir.glob(
      "{#{folders}}/**/*.{#{exts}}"
    )
  end

  task :compile do
    # See: https://gitlab.com/gitlab-org/gitlab-ce/issues/33014#note_31218998
    FileUtils.touch(File.join(Rails.root, 'locale/gitlab.pot'))

    Rake::Task['gettext:po_to_json'].invoke
  end

  desc 'Lint all po files in `locale/'
  task lint: :environment do
    require 'simple_po_parser'
    require 'gitlab/utils'

    FastGettext.silence_errors
    files = Dir.glob(Rails.root.join('locale/*/gitlab.po'))

    linters = files.map do |file|
      locale = File.basename(File.dirname(file))

      Gitlab::I18n::PoLinter.new(file, locale)
    end

    pot_file = Rails.root.join('locale/gitlab.pot')
    linters.unshift(Gitlab::I18n::PoLinter.new(pot_file))

    failed_linters = linters.select { |linter| linter.errors.any? }

    if failed_linters.empty?
      puts 'All PO files are valid.'
    else
      failed_linters.each do |linter|
        report_errors_for_file(linter.po_path, linter.errors)
      end

      raise "Not all PO-files are valid: #{failed_linters.map(&:po_path).to_sentence}"
    end
  end

  task :updated_check do
    # Removing all pre-translated files speeds up `gettext:find` as the
    # files don't need to be merged.
    # Having `LC_MESSAGES/gitlab.mo files present also confuses the output.
    FileUtils.rm Dir['locale/**/gitlab.*']

    # Make sure we start out with a clean pot.file
    `git checkout -- locale/gitlab.pot`

    # `gettext:find` writes touches to temp files to `stderr` which would cause
    # `static-analysis` to report failures. We can ignore these.
    silence_stream($stderr) do
      Rake::Task['gettext:find'].invoke
    end

    pot_diff = `git diff -- locale/gitlab.pot`.strip

    # reset the locale folder for potential next tasks
    `git checkout -- locale`

    if pot_diff.present?
      raise <<~MSG
        Newly translated strings found, please add them to `gitlab.pot` by running:

          rm locale/**/gitlab.*; bin/rake gettext:find; git checkout -- locale/*/gitlab.po

        Then commit and push the resulting changes to `locale/gitlab.pot`.

        The diff was:

        #{pot_diff}
      MSG
    end
  end

  def report_errors_for_file(file, errors_for_file)
    puts "Errors in `#{file}`:"

    errors_for_file.each do |message_id, errors|
      puts "  #{message_id}"
      errors.each do |error|
        spaces = ' ' * 4
        error = error.lines.join("#{spaces}")
        puts "#{spaces}#{error}"
      end
    end
  end
end
