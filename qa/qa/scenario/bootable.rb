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
              # The argument for the --set-feature-flags option should look something like "flag1=enabled,flag2=disabled"
              # Here we translate that string into a hash, e.g.: { 'flag1' => 'enabled', 'flag2' => "disabled" }
              case opt.name
              when :set_feature_flags
                parser.on(opt.arg, opt.desc) do |flags|
                  value = flags.split(',').each_with_object({}) do |pair, hash|
                    flag_name, flag_value = pair.split('=')
                    raise '--set-feature-flags requires flag name and flag state for each flag, e.g., flag1=enabled,flag2=disabled' unless flag_name && flag_value

                    hash[flag_name] = flag_value
                  end
                  Runtime::Scenario.define(opt.name, value)
                end

                next
              when :count_examples_only, :test_metadata_only
                parser.on(opt.arg, opt.desc) do |value|
                  ENV["QA_RSPEC_DRY_RUN"] = "true"
                  Runtime::Scenario.define(opt.name, value)
                end

                next
              end

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
