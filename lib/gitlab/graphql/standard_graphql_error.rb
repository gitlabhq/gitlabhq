# frozen_string_literal: true

# rubocop:disable Cop/CustomErrorClass

module Gitlab
  module Graphql
    class StandardGraphqlError < StandardError
    end
  end
end
