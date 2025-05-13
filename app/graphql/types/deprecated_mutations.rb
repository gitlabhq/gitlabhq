# frozen_string_literal: true

module Types
  module DeprecatedMutations
    extend ActiveSupport::Concern

    prepended do
      mount_aliased_mutation 'WorkItemExport', Mutations::WorkItems::CSV::Export,
        deprecated: { reason: 'Use WorkItemsCsvExport', milestone: '18.0' }
    end
  end
end
