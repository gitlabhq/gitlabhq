require "gettext_i18n_rails/tasks"

namespace :gettext do
  # Customize list of translatable files
  # See: https://github.com/grosser/gettext_i18n_rails#customizing-list-of-translatable-files
  def files_to_translate
    folders = %W(app lib config #{locale_path}).join(',')
    exts = %w(rb erb haml slim rhtml js jsx vue coffee handlebars hbs mustache).join(',')

    Dir.glob(
      "{#{folders}}/**/*.{#{exts}}"
    )
  end
end
