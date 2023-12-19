# frozen_string_literal: true

# Helpers related reading/writing definition files
module InternalEventsCli
  module Helpers
    module Files
      def prompt_to_save_file(filepath, content)
        cli.say <<~TEXT.chomp
          #{format_info('Preparing to generate definition with these attributes:')}
          #{filepath}
          #{content}
        TEXT

        if File.exist?(filepath)
          cli.error("Oh no! This file already exists!\n")

          return if cli.no?(format_prompt('Overwrite file?'))

          write_to_file(filepath, content, 'update')
        elsif cli.yes?(format_prompt('Create file?'))
          write_to_file(filepath, content, 'create')
        end
      end

      def file_saved_message(verb, filepath)
        "    #{format_selection(verb)} #{filepath}"
      end

      def write_to_file(filepath, content, verb)
        File.write(filepath, content)

        file_saved_message(verb, filepath).tap { |message| cli.say "\n#{message}\n" }
      end
    end
  end
end
