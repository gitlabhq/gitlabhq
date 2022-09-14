# frozen_string_literal: true

require 'forwardable'

require_relative '../lib/gitlab_edition'

module RuboCop
  module CodeReuseHelpers
    extend Forwardable

    def_delegators :GitlabEdition, :ee?, :jh?

    # Returns true for a `(send const ...)` node.
    def send_to_constant?(node)
      node.type == :send && node.children&.first&.type == :const
    end

    # Returns `true` if the name of the receiving constant ends with a given
    # `String`.
    def send_receiver_name_ends_with?(node, suffix)
      return false unless send_to_constant?(node)

      receiver_name = name_of_receiver(node)

      receiver_name != suffix &&
        receiver_name.end_with?(suffix)
    end

    # Returns the file path (as a `String`) for an AST node.
    def file_path_for_node(node)
      node.location.expression.source_buffer.name
    end

    # Returns the name of a constant node.
    #
    # Given the AST node `(const nil? :Foo)`, this method will return `:Foo`.
    def name_of_constant(node)
      node.children[1]
    end

    # Returns true if the given node resides in app/finders or ee/app/finders.
    def in_finder?(node)
      in_app_directory?(node, 'finders')
    end

    # Returns true if the given node resides in app/models or ee/app/models.
    def in_model?(node)
      in_app_directory?(node, 'models')
    end

    # Returns true if the given node resides in app/services or ee/app/services.
    def in_service_class?(node)
      in_app_directory?(node, 'services')
    end

    # Returns true if the given node resides in app/presenters or
    # ee/app/presenters.
    def in_presenter?(node)
      in_app_directory?(node, 'presenters')
    end

    # Returns true if the given node resides in app/serializers or
    # ee/app/serializers.
    def in_serializer?(node)
      in_app_directory?(node, 'serializers')
    end

    # Returns true if the given node resides in app/workers or ee/app/workers.
    def in_worker?(node)
      in_app_directory?(node, 'workers')
    end

    # Returns true if the given node resides in app/controllers or
    # ee/app/controllers.
    def in_controller?(node)
      in_app_directory?(node, 'controllers')
    end

    # Returns true if the given node resides in app/graphql or ee/app/graphql.
    def in_graphql?(node)
      in_app_directory?(node, 'graphql')
    end

    # Returns true if the given node resides in lib/api or ee/lib/api.
    def in_api?(node)
      in_lib_directory?(node, 'api')
    end

    # Returns true if the given node resides in spec or ee/spec.
    def in_spec?(node)
      file_path_for_node(node).start_with?(
        ce_spec_directory,
        ee_spec_directory
      )
    end

    # Returns `true` if the given AST node resides in the given directory,
    # relative to app and/or ee/app.
    def in_app_directory?(node, directory)
      file_path_for_node(node).start_with?(
        File.join(ce_app_directory, directory),
        File.join(ee_app_directory, directory)
      )
    end

    # Returns `true` if the given AST node resides in the given directory,
    # relative to lib and/or ee/lib.
    def in_lib_directory?(node, directory)
      file_path_for_node(node).start_with?(
        File.join(ce_lib_directory, directory),
        File.join(ee_lib_directory, directory)
      )
    end

    # Returns true if the given node resides in app/graphql/{directory},
    # ee/app/graphql/{directory}, or ee/app/graphql/ee/{directory}.
    def in_graphql_directory?(node, directory)
      in_app_directory?(node, "graphql/#{directory}") ||
        in_app_directory?(node, "graphql/ee/#{directory}")
    end

    # Returns the receiver name of a send node.
    #
    # For the AST node `(send (const nil? :Foo) ...)` this would return
    # `'Foo'`.
    def name_of_receiver(node)
      name_of_constant(node.children.first).to_s
    end

    # Yields every defined class method in the given AST node.
    def each_class_method(node)
      return to_enum(__method__, node) unless block_given?

      # class << self
      #   def foo
      #   end
      # end
      node.each_descendant(:sclass) do |sclass|
        sclass.each_descendant(:def) do |def_node|
          yield def_node
        end
      end

      # def self.foo
      # end
      node.each_descendant(:defs) do |defs_node|
        yield defs_node
      end
    end

    # Yields every send node found in the given AST node.
    def each_send_node(node, &block)
      node.each_descendant(:send, &block)
    end

    # Registers a RuboCop offense for a `(send)` node with a receiver that ends
    # with a given suffix.
    #
    # node - The AST node to check.
    # suffix - The suffix of the receiver name, such as "Finder".
    # message - The message to use for the offense.
    def disallow_send_to(node, suffix, message)
      each_send_node(node) do |send_node|
        next unless send_receiver_name_ends_with?(send_node, suffix)

        add_offense(send_node, message: message)
      end
    end

    def ce_app_directory
      File.join(rails_root, 'app')
    end

    def ee_app_directory
      File.join(rails_root, 'ee', 'app')
    end

    def ce_lib_directory
      File.join(rails_root, 'lib')
    end

    def ee_lib_directory
      File.join(rails_root, 'ee', 'lib')
    end

    def ce_spec_directory
      File.join(rails_root, 'spec')
    end

    def ee_spec_directory
      File.join(rails_root, 'ee', 'spec')
    end

    def rails_root
      File.expand_path('..', __dir__)
    end
  end
end
