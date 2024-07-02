# frozen_string_literal: true

module Gitlab
  module Cng
    module Helpers
      # Thor command specific helpers
      #
      module Thor
        # Register all public methods of Thor class inside another Thor class as commands
        #
        # @param [Thor] klass
        # @return [void]
        def register_commands(klass)
          raise "#{klass} is not a Thor class" unless klass < ::Thor

          klass.commands.each do |name, command|
            raise "Tried to register command '#{name}' but the command already exists" if commands[name]

            # check if the method takes arguments
            pass_args = klass.new.method(name).arity != 0

            commands[name] = command
            define_method(name) do |*args|
              pass_args ? invoke(klass, name, *args) : invoke(klass, name)
            end
          end
        end
      end
    end
  end
end
