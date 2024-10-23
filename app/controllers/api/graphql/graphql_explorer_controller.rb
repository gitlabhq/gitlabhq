# frozen_string_literal: true

module API
  module Graphql
    class GraphqlExplorerController < BaseActionController
      include Gitlab::GonHelper

      def show
        # We need gon to setup gon.relative_url_root which is used by our Apollo client
        add_gon_variables
      end
    end
  end
end
