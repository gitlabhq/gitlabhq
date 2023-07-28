# frozen_string_literal: true

# Gitaly note: JV: no RPC's here.

module Gitlab
  module Git
    class GitmodulesParser
      def initialize(content)
        @content = content
      end

      # Parses the contents of a .gitmodules file and returns a hash of
      # submodule information, indexed by path.
      def parse
        reindex_by_path(get_submodules_by_name)
      end

      private

      class State
        def initialize
          @result = {}
          @current_submodule = nil
        end

        def start_section(section)
          # In some .gitmodules files (e.g. nodegit's), a header
          # with the same name appears multiple times; we want to
          # accumulate the configs across these
          @current_submodule = @result[section] || { 'name' => section }
          @result[section] = @current_submodule
        end

        def set_attribute(attr, value)
          @current_submodule[attr] = value
        end

        def section_started?
          !@current_submodule.nil?
        end

        def submodules_by_name
          @result
        end
      end

      def get_submodules_by_name
        iterator = State.new

        @content.split("\n").each_with_object(iterator) do |text, iterator|
          text.chomp!

          next if /^\s*#/.match?(text)

          if text =~ /\A\[submodule "(?<name>[^"]+)"\]\z/
            iterator.start_section($~[:name])
          else
            next unless iterator.section_started?

            next unless text =~ /\A\s*(?<key>\w+)\s*=\s*(?<value>.*)\z/

            value = $~[:value]
            iterator.set_attribute($~[:key], value)
          end
        end

        iterator.submodules_by_name
      end

      def reindex_by_path(submodules_by_name)
        # Convert from an indexed by name to an array indexed by path
        # If a submodule doesn't have a path, it is considered bogus
        # and is ignored
        submodules_by_name.each_with_object({}) do |(_name, data), results|
          path = data.delete 'path'
          next unless path

          results[path] = data
        end
      end
    end
  end
end
