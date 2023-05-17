# frozen_string_literal: true

module Gitlab
  module I18n
    # Pluralization formulas per locale used by FastGettext via:
    # `FastGettext.pluralisation_rule.call(count)`.
    module Pluralization
      # rubocop:disable all
      MAP = {
        "bg" => ->(n) { (n != 1) },
        "cs_CZ" => ->(n) { (n==1) ? 0 : (n>=2 && n<=4) ? 1 : 3 },
        "da_DK" => ->(n) { (n != 1) },
        "de" => ->(n) { (n != 1) },
        "en" => ->(n) { (n != 1) },
        "eo" => ->(n) { (n != 1) },
        "es" => ->(n) { (n != 1) },
        "fil_PH" => ->(n) { (n > 1) },
        "fr" => ->(n) { (n > 1) },
        "gl_ES" => ->(n) { (n != 1) },
        "id_ID" => ->(n) { 0 },
        "it" => ->(n) { (n != 1) },
        "ja" => ->(n) { 0 },
        "ko" => ->(n) { 0 },
        "nb_NO" => ->(n) { (n != 1) },
        "nl_NL" => ->(n) { (n != 1) },
        "pl_PL" => ->(n) { (n==1 ? 0 : (n%10>=2 && n%10<=4) && (n%100<12 || n%100>14) ? 1 : n!=1 && (n%10>=0 && n%10<=1) || (n%10>=5 && n%10<=9) || (n%100>=12 && n%100<=14) ? 2 : 3) },
        "pt_BR" => ->(n) { (n != 1) },
        "ro_RO" => ->(n) { (n==1 ? 0 : (n==0 || (n%100>0 && n%100<20)) ? 1 : 2) },
        "ru" => ->(n) { ((n%10==1 && n%100!=11) ? 0 : ((n%10 >= 2 && n%10 <=4 && (n%100 < 12 || n%100 > 14)) ? 1 : ((n%10 == 0 || (n%10 >= 5 && n%10 <=9)) || (n%100 >= 11 && n%100 <= 14)) ? 2 : 3)) },
        "si_LK" => ->(n) { (n != 1) },
        "tr_TR" => ->(n) { (n != 1) },
        "uk" => ->(n) { ((n%10==1 && n%100!=11) ? 0 : ((n%10 >= 2 && n%10 <=4 && (n%100 < 12 || n%100 > 14)) ? 1 : ((n%10 == 0 || (n%10 >= 5 && n%10 <=9)) || (n%100 >= 11 && n%100 <= 14)) ? 2 : 3)) },
        "zh_CN" => ->(n) { 0 },
        "zh_HK" => ->(n) { 0 },
        "zh_TW" => ->(n) { 0 }
      }.freeze
      # rubocop:enable

      NOT_FOUND_ERROR = lambda do |locale|
        po = File.expand_path("../../../locale/#{locale}/gitlab.po", __dir__)

        forms = File.read(po)[/Plural-Forms:.*; plural=(.*?);\\n/, 1] if File.exist?(po)
        suggestion = <<~TEXT if forms
          Add the following line to #{__FILE__}:

            MAP = {
              ...
              "#{locale}" => ->(n) { #{forms} },
              ...
            }.freeze

          This rule was extracted from #{po}.
        TEXT

        raise ArgumentError, <<~MESSAGE
          Missing pluralization rule for locale #{locale.inspect}.

          #{suggestion}
        MESSAGE
      end

      def self.call(count)
        locale = FastGettext.locale

        MAP.fetch(locale, &NOT_FOUND_ERROR).call(count)
      end

      def self.install_on(klass)
        klass.extend(FastGettextClassMethods)
      end

      module FastGettextClassMethods
        # FastGettext allows to set the rule via
        # `FastGettext.pluralisation_rule=` which is on thread-level.
        #
        # Because we are patching FastGettext at boot time per thread values
        # won't work so we have to override the method implementation.
        #
        # `FastGettext.pluralisation_rule=` has now no effect.
        def pluralisation_rule
          Gitlab::I18n::Pluralization
        end
      end
    end
  end
end
