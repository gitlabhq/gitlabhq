# frozen_string_literal: true

require 'fileutils'
require 'yard'

# This file has been copied from https://github.com/rubocop/rubocop/blob/master/lib/rubocop/cops_documentation_generator.rb
# It has been altered to work with Markdown, and the changes will be pushed upstream

# rubocop:disable Lint/RedundantCopDisableDirective -- Don't remove the disables already in place from the upstream repo, so it's easier to merge back

# Class for generating documentation of all cops departments
# @api private
module RuboCop
  class CopsDocumentationGenerator # rubocop:disable Metrics/ClassLength -- Exception already existed in upstream repo
    module Formatters
      class Markdown
        def to_filename(base_name)
          "#{base_name}.md"
        end

        def to_header(text, level: 1)
          "\n#{'#' * level} #{text}\n\n"
        end

        def to_link(link_to, text, anchor: nil)
          link_to = "#{link_to}##{anchor}" if anchor

          "[#{text}](#{link_to})"
        end

        def to_bullet_point(text)
          "- #{text}\n"
        end

        def to_anchor(anchor_text)
          "<a name=\"#{anchor_text}\"></a>\n"
        end

        def to_comment(comment)
          <<~COMMENT
            <!---
            #{comment}
            -->
          COMMENT
        end

        def to_code(ruby_code)
          <<~CODE
            ```ruby
            #{ruby_code.text.gsub('@good', '# good').gsub('@bad', '# bad').strip}
            ```
          CODE
        end

        def to_table(headers, content)
          table = "| #{headers.join(' | ')} |\n"
          table += "| #{headers.map { |header| ('-' * header.length) }.join(' | ')} |\n"

          content.each do |row|
            table += "| #{row.join(' | ')} |\n"
          end
          table
        end
      end

      class HugoMarkdown < Markdown
        def to_link(link_to, text, anchor: nil)
          link_to = "#{link_to}##{anchor}" if anchor

          %{[#{text}]({{< ref "#{link_to}" >}})}
        end
      end

      class Asciidoc
        def to_filename(base_name)
          "#{base_name}.adoc"
        end

        def to_header(text, level: 1)
          "#{'=' * level} #{text}\n\n"
        end

        def to_link(link_to, text, anchor: nil)
          if anchor
            "xref:#{link_to}[#{text}#{anchor}]"
          else
            "xref:#{link_to}[#{text}]"
          end
        end

        def to_code(ruby_code)
          content = +"[source,ruby]\n----\n"
          content << ruby_code.text.gsub('@good', '# good').gsub('@bad', '# bad').strip
          content << "\n----\n"
          content
        end

        def to_bullet_point(text)
          "* #{text}\n"
        end

        def to_anchor(anchor_text)
          "[##{anchor_text}]\n"
        end

        def to_comment(comment)
          <<~COMMENT
            ////
            #{comment}
            ////
          COMMENT
        end

        def to_table(header, content)
          table = ['|===', "| #{header.join(' | ')}\n\n"].join("\n")
          marked_contents = content.map do |plain_content|
            # Escape `|` with backslash to prevent the regexp `|` is not used as a table separator.
            plain_content.map { |c| "| #{c.gsub('|', '\|')}" }.join("\n")
          end
          table << marked_contents.join("\n\n")
          table << "\n|===\n"
        end
      end
    end

    include ::RuboCop::Cop::Documentation

    CopData = Struct.new(
      :cop, :description, :example_objects, :safety_objects, :see_objects, :config, keyword_init: true
    )

    # rubocop:disable Layout/HashAlignment -- Rule differs in upstream repo
    STRUCTURE = {
      name:                  ->(data) { cop_header(data.cop) },
      required_ruby_version: ->(data) { required_ruby_version(data.cop) },
      properties:            ->(data) { properties(data.cop) },
      description:           ->(data) { "#{data.description}\n" },
      safety:                ->(data) { safety_object(data.safety_objects, data.cop) },
      examples:              ->(data) { examples(data.example_objects, data.cop) },
      configuration:         ->(data) { configurations(data.cop.department, data.config, data.cop) },
      references:            ->(data) { references(data.cop, data.see_objects) }
    }.freeze
    # rubocop:enable Layout/HashAlignment

    # This class will only generate documentation for cops that belong to one of
    # the departments given in the `departments` array. E.g. if we only wanted
    # documentation for Lint cops:
    #
    #   CopsDocumentationGenerator.new(departments: ['Lint']).call
    #
    # You can append additional information:
    #
    #   callback = ->(data) { required_rails_version(data.cop) }
    #   CopsDocumentationGenerator.new(extra_info: { ruby_version: callback }).call
    #
    # This will insert the string returned from the lambda _after_ the section from RuboCop itself.
    # See `CopsDocumentationGenerator::STRUCTURE` for available sections.
    #
    def initialize(
      formatter: Formatters::Asciidoc.new, cops_registry: RuboCop::Cop::Registry.global,
      departments: [], extra_info: {}, base_dir: Dir.pwd
    )
      @departments = departments.map(&:to_sym).sort!
      @extra_info = extra_info
      @formatter = formatter
      @cops = cops_registry
      @config = RuboCop::ConfigLoader.default_configuration
      @base_dir = base_dir
      @docs_path = "#{base_dir}/docs/modules/ROOT"
      FileUtils.mkdir_p("#{@docs_path}/pages")
    end

    def call
      YARD::Registry.load!
      departments.each { |department| print_cops_of_department(department) }

      print_table_of_contents
    end

    private

    attr_reader :departments, :cops, :config, :docs_path, :formatter

    def cops_of_department(department)
      cops.with_department(department).sort!
    end

    def cops_body(data)
      check_examples_to_have_the_default_enforced_style!(data.example_objects, data.cop)

      content = +''
      STRUCTURE.each do |section, block|
        content << instance_exec(data, &block)
        content << @extra_info[section].call(data) if @extra_info[section]
      end
      content
    end

    def check_examples_to_have_the_default_enforced_style!(example_objects, cop)
      return if example_objects.none?

      examples_describing_enforced_style = example_objects.map(&:name).grep(/EnforcedStyle:/)
      return if examples_describing_enforced_style.none?

      if examples_describing_enforced_style.index { |name| name.match?('default') }.nonzero?
        raise "Put the example with the default EnforcedStyle on top for #{cop.cop_name}"
      end

      return if examples_describing_enforced_style.any? { |name| name.match?('default') }

      raise "Specify the default EnforcedStyle for #{cop.cop_name}"
    end

    def examples(example_objects, cop)
      return '' if example_objects.none?

      example_objects.each_with_object(cop_subsection('Examples', cop).dup) do |example, content|
        content << "\n" unless content.end_with?("\n\n")
        content << example_header(example.name, cop) unless example.name == ''
        content << formatter.to_code(example)
      end
    end

    def safety_object(safety_objects, cop)
      return '' if safety_objects.all? { |s| s.text.blank? }

      safety_objects.each_with_object(cop_subsection('Safety', cop).dup) do |safety_object, content|
        next if safety_object.text.blank?

        content << "\n" unless content.end_with?("\n\n")
        content << safety_object.text
        content << "\n"
      end
    end

    def required_ruby_version(cop)
      return '' unless cop.respond_to?(:required_minimum_ruby_version)

      if cop.required_minimum_ruby_version
        requirement = cop.required_minimum_ruby_version
      elsif cop.required_maximum_ruby_version
        requirement = "<= #{cop.required_maximum_ruby_version}"
      else
        return ''
      end

      "NOTE: Requires Ruby version #{requirement}\n\n"
    end

    # rubocop:disable Metrics/MethodLength -- Exception already existed in upstream repo
    def properties(cop)
      header = [
        'Enabled by default', 'Safe', 'Supports autocorrection', 'Version Added',
        'Version Changed'
      ]
      autocorrect = if cop.support_autocorrect? # rubocop:disable Cop/LineBreakAroundConditionalBlock -- Rule differs in upstream repo
                      context = cop.new.always_autocorrect? ? 'Always' : 'Command-line only'

                      "#{context}#{' (Unsafe)' unless cop.new(config).safe_autocorrect?}"
                    else
                      'No'
                    end
      cop_config = config.for_cop(cop)
      content = [[
        cop_status(cop_config.fetch('Enabled')),
        cop_config.fetch('Safe', true) ? 'Yes' : 'No',
        autocorrect,
        cop_config.fetch('VersionAdded', '-'),
        cop_config.fetch('VersionChanged', '-')
      ]]
      "#{formatter.to_table(header, content)}\n"
    end
    # rubocop:enable Metrics/MethodLength

    def cop_header(cop)
      content = +"\n"
      content << formatter.to_anchor(to_anchor(cop.cop_name))
      content << formatter.to_header(cop.cop_name, level: 2)
      content
    end

    def cop_subsection(title, cop)
      content = +"\n"
      content << formatter.to_anchor("#{to_anchor(title)}-#{to_anchor(cop.cop_name)}")
      content << formatter.to_header(title, level: 3)
      content
    end

    def example_header(title, cop)
      content = +formatter.to_anchor("#{to_anchor(title)}-#{to_anchor(cop.cop_name)}")
      content << formatter.to_header(title, level: 4)
      content
    end

    def configurations(department, pars, cop) # rubocop:disable Metrics/MethodLength -- Rule differs in upstream repo
      return '' if pars.empty?

      header = ['Name', 'Default value', 'Configurable values']
      configs = pars
                .each_key
                .reject { |key| key.start_with?('Supported') }
                .reject { |key| key.start_with?('AllowMultipleStyles') }
      content = configs.map do |name|
        configurable = configurable_values(pars, name)
        default = format_table_value(pars[name])

        [configuration_name(department, name), default, configurable]
      end

      cop_subsection('Configurable attributes', cop) + formatter.to_table(header, content)
    end

    def configuration_name(department, name)
      return name unless name == 'AllowMultilineFinalElement'

      filename = formatter.to_filename(department_to_basename(department))
      "xref:#{filename}#allowmultilinefinalelement[AllowMultilineFinalElement]"
    end

    # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength  -- Exception already existed in upstream repo
    def configurable_values(pars, name)
      case name
      when /^Enforced/
        supported_style_name = RuboCop::Cop::Util.to_supported_styles(name)
        format_table_value(pars[supported_style_name])
      when 'IndentationWidth'
        'Integer'
      when 'Database'
        format_table_value(pars['SupportedDatabases'])
      else
        case pars[name]
        when String
          'String'
        when Integer
          'Integer'
        when Float
          'Float'
        when true, false
          'Boolean'
        when Array
          'Array'
        else
          ''
        end
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity,Metrics/MethodLength

    def format_table_value(val) # rubocop:disable Metrics/MethodLength -- Rule differs in upstream repo
      value =
        case val
        when Array
          if val.empty?
            '`[]`'
          else
            val.map { |config| format_table_value(config) }.join(', ')
          end
        else
          wrap_backtick(val.nil? ? '<none>' : val)
        end
      value.gsub("#{@base_dir}/", '').rstrip
    end

    def wrap_backtick(value)
      if value.is_a?(String)
        # Use `+` to prevent text like `**/*.gemspec`, `spec/**/*` from being bold.
        value.include?('*') ? "`+#{value}+`" : "`#{value}`"
      else
        "`#{value}`"
      end
    end

    def references(cop, see_objects) # rubocop:disable Metrics/AbcSize -- Exception already existed in upstream repo
      cop_config = config.for_cop(cop)
      urls = RuboCop::Cop::MessageAnnotator.new(config, cop.name, cop_config, {}).urls
      return '' if urls.empty? && see_objects.empty?

      content = cop_subsection('References', cop)
      content << urls.map { |url| "* #{url}" }.join("\n")
      content << "\n" unless urls.empty?
      content << see_objects.map { |see| "* #{see.name}" }.join("\n")
      content << "\n" unless see_objects.empty?
      content
    end

    def footer_for_department(department)
      return '' unless department == :Layout

      filename = formatter.to_filename("#{department_to_basename(department)}_footer")
      file = "#{docs_path}/partials/#{filename}"
      return '' unless File.exist?(file)

      "\ninclude::../partials/#{filename}[]\n"
    end

    # rubocop:disable Metrics/MethodLength -- Exception already existed in upstream repo
    def print_cops_of_department(department)
      selected_cops = cops_of_department(department)
      content = formatter.to_comment(+<<~HEADER)
        Do NOT edit this file by hand directly, as it is automatically generated.

        Please make any necessary changes to the cop documentation within the source files themselves.
      HEADER
      content += formatter.to_header(department)
      selected_cops.each { |cop| content << print_cop_with_doc(cop) }
      content << footer_for_department(department)
      file_name = formatter.to_filename("#{docs_path}/pages/#{department_to_basename(department)}")
      File.open(file_name, 'w') do |file|
        puts "* generated #{file_name}"
        file.write("#{content.strip}\n")
      end
    end
    # rubocop:enable Metrics/MethodLength

    def print_cop_with_doc(cop) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength -- Exception already existed in upstream repo
      cop_config = config.for_cop(cop)
      non_display_keys = %w[
        AutoCorrect Description Enabled StyleGuide Reference Safe SafeAutoCorrect VersionAdded
        VersionChanged
      ]
      pars = cop_config.reject { |k| non_display_keys.include? k }
      description = 'No documentation'
      example_objects = safety_objects = see_objects = []
      cop_code(cop) do |code_object|
        description = code_object.docstring unless code_object.docstring.blank?
        example_objects = code_object.tags('example')
        safety_objects = code_object.tags('safety')
        see_objects = code_object.tags('see')
      end
      data = CopData.new(cop: cop, description: description, example_objects: example_objects,
                         safety_objects: safety_objects, see_objects: see_objects, config: pars) # rubocop:disable Layout/ArgumentAlignment  -- Exception already existed in upstream repo
      cops_body(data)
    end

    def cop_code(cop)
      YARD::Registry.all(:class).detect do |code_object|
        next unless RuboCop::Cop::Badge.for(code_object.to_s) == cop.badge

        yield code_object
      end
    end

    def table_of_content_for_department(department)
      type_title = department[0].upcase + department[1..]
      filename = formatter.to_filename(department_to_basename(department))
      content = +formatter.to_header("Department #{formatter.to_link(filename, type_title)}", level: 3)
      cops_of_department(department).each do |cop|
        anchor = to_anchor(cop.cop_name)
        content << formatter.to_bullet_point(formatter.to_link(filename, cop.cop_name, anchor:))
      end

      content
    end

    def print_table_of_contents
      path = formatter.to_filename("#{docs_path}/pages/cops")

      File.write(path, table_contents) and return unless File.exist?(path) # rubocop:disable Style/AndOr -- Rule differs in upstream repo

      original = File.read(path)
      content = +"// START_COP_LIST\n\n"

      content << table_contents

      content << "\n// END_COP_LIST"

      content = original.sub(%r{// START_COP_LIST.+// END_COP_LIST}m, content)
      File.write(path, content)
    end

    def table_contents
      departments.map { |department| table_of_content_for_department(department) }.join("\n")
    end

    def cop_status(status)
      return 'Disabled' unless status

      status == 'pending' ? 'Pending' : 'Enabled'
    end

    # HTML anchor are somewhat limited in what characters they can contain, just
    # accept a known-good subset. As long as it's consistent it doesn't matter.
    #
    # Style/AccessModifierDeclarations => styleaccessmodifierdeclarations
    # OnlyFor: [] (default) => onlyfor_-__-_default_
    def to_anchor(title)
      title.delete('/').tr(' ', '-').gsub(/[^a-zA-Z0-9-]/, '_').downcase
    end
  end
end

# rubocop:enable Lint/RedundantCopDisableDirective
