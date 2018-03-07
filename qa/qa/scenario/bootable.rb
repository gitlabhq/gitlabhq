require 'optparse'

module QA
  module Scenario
    module Bootable
      Option = Struct.new(:name, :arg, :desc)

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def launch!(argv)
          return self.perform(*argv) unless has_attributes?

          arguments = OptionParser.new do |parser|
            options.to_a.each do |opt|
              parser.on(opt.arg, opt.desc) do |value|
                Runtime::Scenario.define(opt.name, value)
              end
            end
          end

          arguments.parse!(argv)

          self.perform(**Runtime::Scenario.attributes)
        end

        private

        def attribute(name, arg, desc = '')
          options.push(Option.new(name, arg, desc))
        end

        def options
          @options ||= []
        end

        def has_attributes?
          options.any?
        end
      end
    end
  end
end
