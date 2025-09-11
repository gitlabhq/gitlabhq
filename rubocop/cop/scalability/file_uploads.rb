# frozen_string_literal: true

module RuboCop
  module Cop
    module Scalability
      # Checks for usage of `type: File` in API parameter declarations.
      # Direct usage of `File` bypasses GitLab's Workhorse upload acceleration and
      # can lead to scalability and security issues. Instead, developers should use
      # `::API::Validations::Types::WorkhorseFile` to handle uploads properly.
      #
      # @example
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
      class FileUploads < RuboCop::Cop::Base
        MSG = 'Do not upload files without workhorse acceleration. ' \
              'Please refer to https://docs.gitlab.com/ee/development/uploads/'

        # @!method file_in_type(node)
        def_node_matcher :file_in_type, <<~PATTERN
          (send nil? {:requires :optional}
            (sym _)
            (hash
              {
                <(pair (sym :types) (array <$(const nil? :File) ...>)) ...>
                <(pair (sym :type) $(const nil? :File)) ...>
              }
            )
          )
        PATTERN

        def on_send(node)
          file_in_type(node) do |file_node|
            add_offense(file_node)
          end
        end
      end
    end
  end
end
