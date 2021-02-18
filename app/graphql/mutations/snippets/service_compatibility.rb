# frozen_string_literal: true

module Mutations
  module Snippets
    # Translates graphql mutation field params to be compatible with those expected by the service layer
    module ServiceCompatibility
      extend ActiveSupport::Concern

      # convert_blob_actions_to_snippet_actions!(args)    -> nil
      #
      # Converts the blob_actions mutation argument into the
      # snippet_actions hash which the service layer expects
      def convert_blob_actions_to_snippet_actions!(args)
        # We need to rename `blob_actions` into `snippet_actions` because
        # it's the expected key param
        args[:snippet_actions] = args.delete(:blob_actions)&.map(&:to_h)

        # Return nil to make it explicit that this method is mutating the args parameter
        nil
      end
    end
  end
end
