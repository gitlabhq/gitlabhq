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
          arguments = OptionParser.new do |parser|
            options.to_a.each do |opt|
              parser.on(opt.arg, opt.desc) do |value|
                Runtime::Scenario.define(opt.name, value)
              end
            end
          end

          arguments.parse!(argv)

          if has_attributes?
            self.perform(**Runtime::Scenario.attributes)
          else
            self.perform(*argv)
          end
        end

        private

        def attribute(name, arg, desc)
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
