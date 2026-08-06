# frozen_string_literal: true

module Issuables
  module RootArguments
    extend ActiveSupport::Concern

    NON_FILTER_ARGUMENTS = %i[sort lookahead include_archived include_subepics].freeze

    def ready?(**args)
      unless filter_provided?(args)
        raise Gitlab::Graphql::Errors::ArgumentError, _('You must provide at least one filter argument for this query')
      end

      super
    end

    private

    def filter_provided?(args)
      args.except(*NON_FILTER_ARGUMENTS).each_value.any? { |value| value == false || value.present? }
    end

    def prepare_finder_params(args)
      super.tap do |prepared|
        prepared[:non_archived] = !prepared.delete(:include_archived)
      end
    end
  end
end
