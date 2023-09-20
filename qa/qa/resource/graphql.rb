# rubocop:todo Naming/FileName
# frozen_string_literal: true

module QA
  module Resource
    module GraphQL
      # All GraphQL queries and mutations use the same path, `/graphql`
      #
      # @return [String]
      def api_get_path
        "/graphql"
      end

      alias_method :api_post_path, :api_get_path
      alias_method :api_delete_path, :api_get_path
    end
  end
end

# rubocop:enable Naming/FileName
