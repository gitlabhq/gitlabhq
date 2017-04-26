require 'gettext_i18n_rails/haml_parser'
require 'gettext_i18n_rails_js/parser/javascript'

VUE_TRANSLATE_REGEX = /{{ ([^{]*)( \| translate) }}/
VUE_TRANSLATE_PLURAL_REGEX = /{{ ([^{]*)( \| translate-plural\((.*), (.*)\)) }}/

module GettextI18nRails
  class HamlParser
    singleton_class.send(:alias_method, :old_convert_to_code, :convert_to_code)

    # We need to convert text in Mustache format
    # to a format that can be parsed by Gettext scripts.
    # If we found a content like "{{ 'Stage' | translate }}"
    # in a HAML file we convert it to "= _('Stage')", that way
    # it can be processed by the "rake gettext:find" script.
    #
    # Overwrites: https://github.com/grosser/gettext_i18n_rails/blob/8396387a431e0f8ead72fc1cd425cad2fa4992f2/lib/gettext_i18n_rails/haml_parser.rb#L9
    def self.convert_to_code(text)
      # {{ 'Stage' | translate }} => = _('Stage')
      text.gsub!(VUE_TRANSLATE_REGEX, "= _(\\1)")

      # {{ 'user' | translate-plural('users', users.size) }} => = n_('user', 'users', users.size)
      text.gsub!(VUE_TRANSLATE_PLURAL_REGEX, "= n_(\\1, \\3, \\4)")

      old_convert_to_code(text)
    end
  end
end

module GettextI18nRailsJs
  module Parser
    module Javascript

      # This is required to tell the `rake gettext:find` script to use the Javascript
      # parser for *.vue files.
      #
      # Overwrites: https://github.com/webhippie/gettext_i18n_rails_js/blob/46c58db6d2053a4f5f36a0eb024ea706ff5707cb/lib/gettext_i18n_rails_js/parser/javascript.rb#L36
      def target?(file)
        [
          ".js",
          ".jsx",
          ".coffee",
          ".vue"
        ].include? ::File.extname(file)
      end

      protected

      # Overwrites: https://github.com/webhippie/gettext_i18n_rails_js/blob/46c58db6d2053a4f5f36a0eb024ea706ff5707cb/lib/gettext_i18n_rails_js/parser/javascript.rb#L46
      def collect_for(value)
        ::File.open(value) do |f|
          f.each_line.each_with_index.collect do |line, idx|
            line.gsub!(VUE_TRANSLATE_REGEX, "__(\\1)")
            line.gsub!(VUE_TRANSLATE_PLURAL_REGEX, "n__(\\1, \\3, \\4)")

            line.scan(invoke_regex).collect do |function, arguments|
              yield(function, arguments, idx + 1)
            end
          end.inject([], :+).compact
        end
      end
    end
  end
end
