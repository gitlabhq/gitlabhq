# frozen_string_literal: true

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

          self.perform(Runtime::Scenario.attributes, *argv)
        end

        private

        def attribute(name, arg, desc = '')
          options.push(Option.new(name, arg, desc))
        end

        def options
          # Scenario options/attributes are global. There's only ever one
          # scenario at a time, but they can be inherited and we want scenarios
          # to share the attributes of their ancestors. For example, `Mattermost`
          # inherits from `Test::Instance::All` but if this were an instance
          # variable then `Mattermost` wouldn't have access to the attributes
          # in `All`
          @@options ||= [] # rubocop:disable Style/ClassVars
        end

        def has_attributes?
          options.any?
        end
      end
    end
  end
end
