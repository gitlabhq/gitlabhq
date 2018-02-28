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
end
