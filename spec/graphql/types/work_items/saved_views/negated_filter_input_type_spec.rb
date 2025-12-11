# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::SavedViews::NegatedFilterInputType, feature_category: :portfolio_management do
  # The purpose of this spec is to check if the SavedViews::NegatedFilterInputType deviates from the arguments of the
  # WorkItems::NegatedWorkItemFilterInputType type. If this test is failing, and:
  #
  # * The argument is intended to be used on the work items listing page, and able to be saved in a saved view, add
  #   this argument to Types::WorkItems::SavedViews::NegatedFilterInputType and add appropriate handling
  #
  # * The argument is NOT intended to be used on the work items listing page, add it to the exception list below
  #
  # * If removing an argument, consider that existing saved views may contain this argument, and will need to be
  #   migrated
  it 'accepts all NegatedWorkItemFilterInputType filter arguments' do
    source_type_arguments = Types::WorkItems::NegatedWorkItemFilterInputType.arguments.keys
    saved_view_type_arguments = described_class.arguments.keys

    # Arguments that exist in NegatedWorkItemFilterInputType but should NOT be in
    # Types::WorkItems::SavedViews::NegatedFilterInputType
    excluded_from_saved_views = %w[]

    # Arguments that exist in Types::WorkItems::SavedViews::NegatedFilterInputType but NOT in
    # NegatedWorkItemFilterInputType (i.e. saved view-specific filters)
    excluded_from_source_type = %w[]

    expected_arguments = source_type_arguments - excluded_from_saved_views

    expect(saved_view_type_arguments - excluded_from_source_type).to match_array(expected_arguments)
  end

  describe 'prepare lambdas' do
    it 'prepares parent_ids by extracting model_ids from GlobalIDs' do
      work_items = create_list(:work_item, 2)
      global_ids = work_items.map(&:to_gid)

      argument = described_class.arguments['parentIds']

      prepared_value = argument.prepare.call(global_ids, nil)

      expect(prepared_value).to match_array(work_items.map { |wi| wi.id.to_s })
    end
  end
end
