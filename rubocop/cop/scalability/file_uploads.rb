# frozen_string_literal: true

module RuboCop
  module Cop
    module Scalability
      # This cop checks for `File` params in API
      #
      # @example
      #
      #   # bad
      #   params do
      #     requires :file, type: File
      #   end
      #
      #   params do
      #     optional :file, type: File
      #   end
      #
      #   # good
      #   params do
      #     requires :file, type: ::API::Validations::Types::WorkhorseFile
      #   end
      #
      #   params do
      #     optional :file, type: ::API::Validations::Types::WorkhorseFile
      #   end
      #
      class FileUploads < RuboCop::Cop::Cop
        MSG = 'Do not upload files without workhorse acceleration. Please refer to https://docs.gitlab.com/ee/development/uploads.html'

        def_node_search :file_type_params?, <<~PATTERN
          (send nil? {:requires :optional} (sym _) (hash <(pair (sym :type)(const nil? :File)) ...>))
        PATTERN

        def_node_search :file_types_params?, <<~PATTERN
          (send nil? {:requires :optional} (sym _) (hash <(pair (sym :types)(array <(const nil? :File) ...>)) ...>))
        PATTERN

        def be_file_param_usage?(node)
          file_type_params?(node) || file_types_params?(node)
        end

        def on_send(node)
          return unless be_file_param_usage?(node)

          add_offense(find_file_param(node), location: :expression)
        end

        private

        def find_file_param(node)
          node.each_descendant.find { |children| file_node_pattern.match(children) }
        end

        def file_node_pattern
          @file_node_pattern ||= RuboCop::NodePattern.new("(const nil? :File)")
        end
      end
    end
  end
end
