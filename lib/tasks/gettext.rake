# frozen_string_literal: true

namespace :gettext do
  desc 'Compile po files to json, for usage in the frontend'
  task :compile do
    # See: https://gitlab.com/gitlab-org/gitlab-foss/issues/33014#note_31218998
    FileUtils.touch(pot_file_path)

    command = [
      "node", "./scripts/frontend/po_to_json.js",
      "--locale-root", Rails.root.join('locale').to_s,
      "--output-dir", Rails.root.join('app/assets/javascripts/locale').to_s
    ]

    abort Rainbow('Error: Unable to convert gettext files to js.').red unless Kernel.system(*command)
  end

  desc 'Regenerate gitlab.pot file'
  task :regenerate do
    require_relative "../../tooling/lib/tooling/gettext_extractor"
    ensure_locale_folder_presence!

    # remove the `pot` file to ensure it's completely regenerated
    FileUtils.rm_f(pot_file_path)

    extractor = Tooling::GettextExtractor.new(
      glob_base: Rails.root
    )
    File.write(pot_file_path, extractor.generate_pot)

    raise 'gitlab.pot file not generated' unless File.exist?(pot_file_path)

    puts <<~MSG
      All done. Please commit the changes to `locale/gitlab.pot`.

      Tip: For even faster regeneration, directly run the following command:
        tooling/bin/gettext_extractor locale/gitlab.pot
    MSG
  end

  desc 'Lint all po files in `locale/'
  task lint: :environment do
    require 'simple_po_parser'
    require 'gitlab/utils/all'
    require 'parallel'

    FastGettext.silence_errors
    files = Dir.glob(Rails.root.join('locale/*/gitlab.po'))

    linters = files.map do |file|
      locale = File.basename(File.dirname(file))

      Gitlab::I18n::PoLinter.new(po_path: file, locale: locale)
    end

    linters.unshift(Gitlab::I18n::PoLinter.new(po_path: pot_file_path))

    failed_linters = Parallel
      .map(linters, progress: 'Linting po files') { |linter| linter if linter.errors.any? }
      .compact

    if failed_linters.empty?
      puts 'All PO files are valid.'
    else
      failed_linters.each do |linter|
        report_errors_for_file(linter.po_path, linter.errors)
      end

      raise "Not all PO-files are valid: #{failed_linters.map(&:po_path).to_sentence}"
    end
  end

  desc 'Check whether gitlab.pot needs updates, used during CI'
  task updated_check: [:regenerate] do
    pot_diff = `git diff -- #{pot_file_path} | grep -E '^(\\+|-)msgid'`.strip

    # reset the locale folder for potential next tasks
    `git checkout -- locale`

    if pot_diff.present?
      raise <<~MSG
        Changes in translated strings found, please update file `#{pot_file_path}` by running:

          tooling/bin/gettext_extractor locale/gitlab.pot

        Then commit and push the resulting changes to `#{pot_file_path}`.

        The diff was:

        #{pot_diff}
      MSG
    end
  end

  private

  def report_errors_for_file(file, errors_for_file)
    puts "Errors in `#{file}`:"

    errors_for_file.each do |message_id, errors|
      puts "  #{message_id}"
      errors.each do |error|
        spaces = ' ' * 4
        error = error.lines.join(spaces.to_s)
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
