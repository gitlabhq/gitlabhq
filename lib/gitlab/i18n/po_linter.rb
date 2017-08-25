require 'simple_po_parser'

module Gitlab
  module I18n
    class PoLinter
      attr_reader :po_path, :entries, :metadata, :locale

      VARIABLE_REGEX = /%{\w*}|%[a-z]/.freeze

      def initialize(po_path, locale = I18n.locale.to_s)
        @po_path = po_path
        @locale = locale
      end

      def errors
        @errors ||= validate_po
      end

      def validate_po
        if parse_error = parse_po
          return 'PO-syntax errors' => [parse_error]
        end

        validate_entries
      end

      def parse_po
        @entries = SimplePoParser.parse(po_path).map { |data| Gitlab::I18n::PoEntry.new(data) }
        @metadata = @entries.detect { |entry| entry.metadata? }
        nil
      rescue SimplePoParser::ParserError => e
        @entries = []
        e.message
      end

      def validate_entries
        errors = {}

        entries.each do |entry|
          next if entry.metadata?

          errors_for_entry = validate_entry(entry)
          errors[join_message(entry.msgid)] = errors_for_entry if errors_for_entry.any?
        end

        errors
      end

      def validate_entry(entry)
        errors = []

        validate_flags(errors, entry)
        validate_variables(errors, entry)
        validate_newlines(errors, entry)
        validate_number_of_plurals(errors, entry)

        errors
      end

      def validate_number_of_plurals(errors, entry)
        return unless metadata&.expected_plurals
        return unless entry.translated?

        if entry.plural? && entry.all_translations.size != metadata.expected_plurals
          errors << "should have #{metadata.expected_plurals} #{'translations'.pluralize(metadata.expected_plurals)}"
        end
      end

      def validate_newlines(errors, entry)
        if entry.msgid.is_a?(Array)
          errors << "is defined over multiple lines, this breaks some tooling."
        end

        if entry.all_translations.any? { |translation| translation.is_a?(Array) }
          errors << "has translations defined over multiple lines, this breaks some tooling."
        end
      end

      def validate_variables(errors, entry)
        if entry.has_singular?
          validate_variables_in_message(errors, entry.msgid, entry.singular_translation)
        end

        if entry.plural?
          entry.plural_translations.each do |translation|
            validate_variables_in_message(errors, entry.plural_id, translation)
          end
        end
      end

      def validate_variables_in_message(errors, message_id, message_translation)
        message_id = join_message(message_id)
        required_variables = message_id.scan(VARIABLE_REGEX)

        validate_unnamed_variables(errors, required_variables)
        validate_translation(errors, message_id, required_variables)
        validate_variable_usage(errors, message_translation, required_variables)
      end

      def validate_translation(errors, message_id, used_variables)
        variables = fill_in_variables(used_variables)

        begin
          Gitlab::I18n.with_locale(locale) do
            translated = if message_id.include?('|')
                           FastGettext::Translation.s_(message_id)
                         else
                           FastGettext::Translation._(message_id)
                         end

            translated % variables
          end

        # `sprintf` could raise an `ArgumentError` when invalid passing something
        # other than a Hash when using named variables
        #
        # `sprintf` could raise `TypeError` when passing a wrong type when using
        # unnamed variables
        #
        # FastGettext::Translation could raise `RuntimeError` (raised as a string),
        # or as subclassess `NoTextDomainConfigured` & `InvalidFormat`
        #
        # `FastGettext::Translation` could raise `ArgumentError` as subclassess
        # `InvalidEncoding`, `IllegalSequence` & `InvalidCharacter`
        rescue ArgumentError, TypeError, RuntimeError => e
          errors << "Failure translating to #{locale} with #{variables}: #{e.message}"
        end
      end

      def fill_in_variables(variables)
        if variables.empty?
          []
        elsif variables.any? { |variable| unnamed_variable?(variable) }
          variables.map do |variable|
            variable == '%d' ? Random.rand(1000) : Gitlab::Utils.random_string
          end
        else
          variables.inject({}) do |hash, variable|
            variable_name = variable[/\w+/]
            hash[variable_name] = Gitlab::Utils.random_string
            hash
          end
        end
      end

      def validate_unnamed_variables(errors, variables)
        if  variables.size > 1 && variables.any? { |variable_name| unnamed_variable?(variable_name) }
          errors << 'is combining multiple unnamed variables'
        end
      end

      def validate_variable_usage(errors, translation, required_variables)
        translation = join_message(translation)

        # We don't need to validate when the message is empty.
        # Translations could fallback to the default, or we could be validating a
        # language that does not have plurals.
        return if translation.empty?

        found_variables = translation.scan(VARIABLE_REGEX)

        missing_variables = required_variables - found_variables
        if missing_variables.any?
          errors << "<#{translation}> is missing: [#{missing_variables.to_sentence}]"
        end

        unknown_variables = found_variables - required_variables
        if unknown_variables.any?
          errors << "<#{translation}> is using unknown variables: [#{unknown_variables.to_sentence}]"
        end
      end

      def unnamed_variable?(variable_name)
        !variable_name.start_with?('%{')
      end

      def validate_flags(errors, entry)
        errors << "is marked #{entry.flag}" if entry.flag
      end

      def join_message(message)
        Array(message).join
      end
    end
  end
end
