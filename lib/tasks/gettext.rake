# frozen_string_literal: true

require "gettext_i18n_rails/tasks"

namespace :gettext do
  task :compile do
    # See: https://gitlab.com/gitlab-org/gitlab-foss/issues/33014#note_31218998
    FileUtils.touch(pot_file_path)

    Rake::Task['gettext:po_to_json'].invoke
  end

  desc 'Regenerate gitlab.pot file'
  task :regenerate do
    ensure_locale_folder_presence!

    # Clean up folders that do not contain a gitlab.po file
    Pathname.new(locale_path).children.each do |child|
      next unless child.directory?

      folder_path = child.to_path

      if File.exist?("#{folder_path}/gitlab.po")
        # remove all translated files to speed up finding
        FileUtils.rm Dir["#{folder_path}/gitlab.*"]
      else
        # remove empty translation folders so we don't generate un-needed .po files
        puts "Deleting #{folder_path} as it does not contain a 'gitlab.po' file."

        FileUtils.rm_r folder_path
      end
    end

    # remove the `pot` file to ensure it's completely regenerated
    FileUtils.rm_f(pot_file_path)

    Rake::Task['gettext:find'].invoke

    # leave only the required changes.
    unless system(*%w(git -c core.hooksPath=/dev/null checkout -- locale/*/gitlab.po))
      raise 'failed to cleanup generated locale/*/gitlab.po files'
    end

    raise 'gitlab.pot file not generated' unless File.exist?(pot_file_path)

    # Remove timestamps from the pot file
    pot_content = File.read pot_file_path
    pot_content.gsub!(/^"POT?\-(?:Creation|Revision)\-Date\:.*\n/, '')
    File.write pot_file_path, pot_content

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

      Gitlab::I18n::PoLinter.new(po_path: file, locale: locale)
    end

    linters.unshift(Gitlab::I18n::PoLinter.new(po_path: pot_file_path))

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
    FileUtils.rm_f pot_file_path

    # `gettext:find` writes touches to temp files to `stderr` which would cause
    # `static-analysis` to report failures. We can ignore these.
    silence_stderr do
      Rake::Task['gettext:find'].invoke
    end

    pot_diff = `git diff -- #{pot_file_path} | grep -E '^(\\+|-)msgid'`.strip

    # reset the locale folder for potential next tasks
    `git checkout -- locale`

    if pot_diff.present?
      raise <<~MSG
        Changes in translated strings found, please update file `#{pot_file_path}` by running:

          bin/rake gettext:regenerate

        Then commit and push the resulting changes to `#{pot_file_path}`.

        The diff was:

        #{pot_diff}
      MSG
    end
  end

  private

  # Customize list of translatable files
  # See: https://github.com/grosser/gettext_i18n_rails#customizing-list-of-translatable-files
  def files_to_translate
    folders = %W(ee app lib config #{locale_path}).join(',')
    exts = %w(rb erb haml slim rhtml js jsx vue handlebars hbs mustache).join(',')

    Dir.glob(
      "{#{folders}}/**/*.{#{exts}}"
    )
  end

  # Disallow HTML from translatable strings
  # See: https://docs.gitlab.com/ee/development/i18n/externalization.html#html
  def html_todolist
    return @html_todolist if defined?(@html_todolist)

    @html_todolist = YAML.safe_load(File.read(Rails.root.join('lib/gitlab/i18n/html_todo.yml')))
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

  def ensure_locale_folder_presence!
    unless Dir.exist?(locale_path)
      raise <<~MSG
      Cannot find '#{locale_path}' folder. Please ensure you're running this task from the gitlab repo.

      MSG
    end
  end

  def locale_path
    @locale_path ||= Rails.root.join('locale')
  end

  def pot_file_path
    @pot_file_path ||= File.join(locale_path, 'gitlab.pot')
  end
end
