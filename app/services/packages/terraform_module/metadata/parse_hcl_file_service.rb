# frozen_string_literal: true

module Packages
  module TerraformModule
    module Metadata
      class ParseHclFileService
        COMMENT_NOTATIONS = %w[// #].freeze
        RESOURCE_REGEX = /resource\s+"([^"]+)"\s+"([^"]+)"/
        QUOTED_STRING_BOUNDARIES_REGEX = /\A"|"\Z/
        TO_KEEP_ARGUMENTS = {
          variable: %w[name type description default].freeze,
          output: %w[name description].freeze
        }.freeze
        DEPENDENCY_REGEXES = {
          source: /source\s*=\s*"([^"]+)"/,
          version: /version\s*=\s*"([^"]+)"/
        }.freeze
        ARGUMENTS = {
          variable: ['default =', 'type =', 'description =', 'validation {', 'sensitive =', 'nullable ='].freeze,
          output: ['description =', 'value ='].freeze
        }.freeze
        HEREDOC_PREFIX_REGEX = /^<<-?/
        PROVIDER_REGEXES = {
          v012: /(\w+-?\w*)\s*=\s*"([^"]+)"/,
          v013: /\s*([\w-]+)\s*=(?=\s*{)/
        }.freeze

        def initialize(file)
          @file = file
          @resources = []
          @modules = []
          @providers = []
          @variables = []
          @outputs = []
          @block_data = {}
          @current_block = nil
          @current_argument = nil
          @heredoc_tag = nil
        end

        def execute
          return ServiceResponse.success(payload: {}) if file.blank?

          file.each do |line|
            next if skip_line?(line)

            process_line(line)
          end

          ServiceResponse.success(payload: { resources: resources, modules: modules, providers: providers,
                                             variables: variables, outputs: outputs })
        end

        private

        attr_reader :file, :resources, :modules, :providers, :variables, :outputs
        attr_accessor :block_data, :current_block, :current_argument, :heredoc_tag

        def skip_line?(line)
          line.strip.empty? || line.strip.start_with?(*COMMENT_NOTATIONS)
        end

        def process_line(line)
          case line
          when /^resource/, /^module/, /^provider/, /^variable/, /^output/, /^terraform/
            start_new_block(determine_block_type(line), line)
          else
            process_block_content(line)
          end
        end

        def determine_block_type(line)
          line.split.first.to_sym
        end

        def start_new_block(block_type, line)
          self.current_block = block_type
          resources << line.match(RESOURCE_REGEX).captures.join('.') if block_type == :resource
          block_data['name'] = line.sub(block_type.to_s, '').split.first if %i[resource terraform].exclude?(block_type)
        end

        def process_block_content(line)
          block_end?(line) ? finalize_current_block : process_block_arguments(line)
        end

        def block_end?(line)
          cond = line.start_with?('}') || (current_argument == :required_providers && line.strip.start_with?('}'))
          cond && line.sub('}', '').strip.empty? && !heredoc_tag
        end

        def finalize_current_block
          return if block_data.empty?

          clean_block_data
          store_block_data
          reset_block_state
        end

        def clean_block_data
          self.block_data = block_data.compact_blank.each_value do |v|
            v.gsub!(QUOTED_STRING_BOUNDARIES_REGEX, '')&.strip!
          end
        end

        def store_block_data
          case current_block
          when :module
            modules << block_data unless block_data['source']&.start_with?('.')
          when :provider, :terraform
            providers << block_data
          when :variable
            variables << block_data.slice(*TO_KEEP_ARGUMENTS[:variable])
          when :output
            outputs << block_data.slice(*TO_KEEP_ARGUMENTS[:output])
          end
        end

        def reset_block_state
          self.block_data = {}
          self.current_block = nil
          self.current_argument = nil
        end

        def process_block_arguments(line)
          case current_block
          when :module
            process_module_arguments(line)
          when :variable, :output
            process_variable_or_output_arguments(line)
          when :terraform
            process_terraform_arguments(line)
          end
        end

        def process_module_arguments(line)
          DEPENDENCY_REGEXES.each do |key, regex|
            block_data[key.to_s] = Regexp.last_match(1) if line =~ regex
          end
        end

        def process_variable_or_output_arguments(line)
          args = ARGUMENTS[current_block.to_sym]
          return process_argument_declaration(line, args) if argument_declared?(line, args)
          return process_heredoc if current_argument && heredoc_tag && line.squish == heredoc_tag

          append_argument_value(line)
        end

        def process_argument_declaration(line, args)
          self.current_argument, argument_value = extract_argument(line, args)
          is_heredoc = current_argument == 'description' && argument_value.start_with?('<<')

          if is_heredoc
            self.heredoc_tag = argument_value.sub(HEREDOC_PREFIX_REGEX, '').strip
            block_data[current_argument] = +''
          else
            block_data[current_argument] = argument_value
          end
        end

        def process_heredoc
          self.heredoc_tag = nil
          self.current_argument = nil
        end

        def append_argument_value(line)
          return unless block_data[current_argument]

          block_data[current_argument] << " #{line.squish}"
        end

        def process_terraform_arguments(line)
          if line.strip.start_with?('required_providers')
            self.current_argument = :required_providers
          elsif current_argument
            process_provider_arguments(line)
          end
        end

        def process_provider_arguments(line)
          if line =~ PROVIDER_REGEXES[:v012] && current_argument == :required_providers
            block_data.merge!('name' => Regexp.last_match(1), 'version' => Regexp.last_match(2))
            finalize_provider_block
          elsif line =~ PROVIDER_REGEXES[:v013]
            finalize_provider_block if block_data.any?
            block_data['name'] = Regexp.last_match(1)
            self.current_argument = block_data['name'].to_sym
          elsif line =~ DEPENDENCY_REGEXES[:source]
            block_data['source'] = Regexp.last_match(1)
          elsif line =~ DEPENDENCY_REGEXES[:version]
            block_data['version'] = Regexp.last_match(1)
          end
        end

        def finalize_provider_block
          providers << block_data
          self.block_data = {}
        end

        def argument_declared?(line, args)
          args.any? { |arg| line.squish.start_with?(arg) && current_argument != arg.split(' ').first }
        end

        def extract_argument(line, args)
          arg = args.find { |arg| line.squish.start_with?(arg) }
          [arg.split(' ').first, line.squish.sub(arg, '').strip]
        end
      end
    end
  end
end
