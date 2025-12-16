# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::SavedViews::UnionedFilterInputType, feature_category: :portfolio_management do
  # The purpose of this spec is to check if the UnionedFilterInputType deviates from the arguments of
  # Types::WorkItems::UnionedWorkItemFilterInputType. If this test is failing, and:
  #
  # * The argument is intended to be used on the work items listing page, and able to be saved in a saved view, add
  #   this argument to Types::WorkItems::SavedViews::UnionedFilterInputType and add appropriate handling
  #
  # * The argument is NOT intended to be used on the work items listing page, add it to the exception list below
  #
  # * If removing an argument, consider that existing saved views may contain this argument, and will need to be
  #   migrated
  it 'accepts all UnionedWorkItemFilterInputType filter arguments' do
    source_type_arguments = Types::WorkItems::UnionedWorkItemFilterInputType.arguments.keys
    saved_view_type_arguments = described_class.arguments.keys

    # Arguments that exist in UnionedWorkItemFilterInputType but should NOT be in
    # Types::WorkItems::SavedViews::UnionedFilterInputType
    excluded_from_saved_views = %w[]

    # Arguments that exist in Types::WorkItems::SavedViews::UnionedFilterInputType but NOT in
    # UnionedWorkItemFilterInputType (i.e. saved view-specific filters)
    excluded_from_source_type = %w[]

    expected_arguments = source_type_arguments - excluded_from_saved_views

    expect(saved_view_type_arguments - excluded_from_source_type).to match_array(expected_arguments)
  end
end
