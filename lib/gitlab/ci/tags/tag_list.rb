# frozen_string_literal: true

module Gitlab
  module Ci
    module Tags
      class TagList < Array
        attr_accessor :owner, :parser

        def initialize(*args)
          @parser = Parser
          add(*args)
        end

        def add(*names)
          extract_and_apply_options!(names)
          concat(names)
          clean!
          self
        end

        def <<(obj)
          add(obj)
        end

        def +(other)
          TagList.new.add(self).add(other)
        end

        def concat(other_tag_list)
          super(other_tag_list).clean!
          self
        end

        def remove(*names)
          extract_and_apply_options!(names)
          delete_if { |name| names.include?(name) }
          self
        end

        def to_s
          tags = frozen? ? dup : self
          tags.clean!

          tags.map do |name|
            name.index(',') ? "\"#{name}\"" : name
          end.join(', ')
        end

        protected

        def clean!
          reject!(&:blank?)
          map!(&:to_s)
          map!(&:strip)
          uniq!

          self
        end

        private

        def extract_and_apply_options!(args)
          options = args.last.is_a?(Hash) ? args.pop : {}
          options.assert_valid_keys :parse, :parser

          parser = options[:parser] || @parser

          args.map! { |a| parser.new(a).parse } if options[:parse] || options[:parser]

          args.flatten!
        end
      end
    end
  end
end
