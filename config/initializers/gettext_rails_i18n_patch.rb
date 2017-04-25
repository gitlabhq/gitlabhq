require 'gettext_i18n_rails/haml_parser'

module GettextI18nRails
  class HamlParser
    singleton_class.send(:alias_method, :old_convert_to_code, :convert_to_code)

    # We need to convert text in Mustache format
    # to a format that can be parsed by Gettext scripts.
    # If we found a content like "{{ 'Stage' | translate }}"
    # in a HAML file we convert it to "= _('Stage')", that way
    # it can be processed by the "rake gettext:find" script.
    def self.convert_to_code(text)
      # {{ 'Stage' | translate }} => = _('Stage')
      text.gsub!(/{{ (.*)( \| translate) }}/, "= _(\\1)")

      # {{ 'user' | translate-plural('users', users.size) }} => = n_('user', 'users', users.size)
      text.gsub!(/{{ (.*)( \| translate-plural\((.*), (.*)\)) }}/, "= n_(\\1, \\3, \\4)")

      old_convert_to_code(text)
    end
  end
end
