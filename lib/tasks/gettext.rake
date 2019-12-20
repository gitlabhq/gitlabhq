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
    # See: https://gitlab.com/gitlab-org/gitlab-foss/issues/33014#note_31218998
    FileUtils.touch(File.join(Rails.root, 'locale/gitlab.pot'))

    Rake::Task['gettext:po_to_json'].invoke
  end

  desc 'Regenerate gitlab.pot file'
  task :regenerate do
    pot_file = 'locale/gitlab.pot'
    # Remove all translated files, this speeds up finding
    FileUtils.rm Dir['locale/**/gitlab.*']
    # remove the `pot` file to ensure it's completely regenerated
    FileUtils.rm_f pot_file

    Rake::Task['gettext:find'].invoke

    # leave only the required changes.
    `git checkout -- locale/*/gitlab.po`

    # Remove timestamps from the pot file
    pot_content = File.read pot_file
    pot_content.gsub!(/^"POT?\-(?:Creation|Revision)\-Date\:.*\n/, '')
    File.write pot_file, pot_content

    puts <<~MSG
    All done. Please commit the changes to `locale/gitlab.pot`.

    MSG
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
    pot_file = 'locale/gitlab.pot'
    # Removing all pre-translated files speeds up `gettext:find` as the
    # files don't need to be merged.
    # Having `LC_MESSAGES/gitlab.mo files present also confuses the output.
    FileUtils.rm Dir['locale/**/gitlab.*']
    FileUtils.rm_f pot_file

    # `gettext:find` writes touches to temp files to `stderr` which would cause
    # `static-analysis` to report failures. We can ignore these.
    silence_stderr do
      Rake::Task['gettext:find'].invoke
    end

    pot_diff = `git diff -- #{pot_file} | grep -E '^(\\+|-)msgid'`.strip

    # reset the locale folder for potential next tasks
    `git checkout -- locale`

    if pot_diff.present?
      raise <<~MSG
        Changes in translated strings found, please update file `#{pot_file}` by running:

          bin/rake gettext:regenerate

        Then commit and push the resulting changes to `#{pot_file}`.

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

  def silence_stderr(&block)
    old_stderr = $stderr.dup
    $stderr.reopen(File::NULL)
    $stderr.sync = true

    yield
  ensure
    $stderr.reopen(old_stderr)
    old_stderr.close
  end
end
