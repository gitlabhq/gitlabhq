require "gettext_i18n_rails/tasks"

namespace :gettext do
  # Customize list of translatable files
  # See: https://github.com/grosser/gettext_i18n_rails#customizing-list-of-translatable-files
  def files_to_translate
    folders = %W(app lib config #{locale_path}).join(',')
    exts = %w(rb erb haml slim rhtml js jsx vue handlebars hbs mustache).join(',')

    Dir.glob(
      "{#{folders}}/**/*.{#{exts}}"
    )
  end

  task :compile do
    # See: https://gitlab.com/gitlab-org/gitlab-ce/issues/33014#note_31218998
    FileUtils.touch(File.join(Rails.root, 'locale/gitlab.pot'))

    Rake::Task['gettext:pack'].invoke
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
