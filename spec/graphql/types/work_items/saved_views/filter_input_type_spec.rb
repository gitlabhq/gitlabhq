# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::SavedViews::FilterInputType, feature_category: :portfolio_management do
  # The purpose of this spec is to check if the FilterInputType deviates from the arguments of the work items resolver
  # query. If this test is failing, and:
  #
  # * The argument is intended to be used on the work items listing page, and able to be saved in a saved view, add
  #   this argument to Types::WorkItems::SavedViews::FilterInputType and add appropriate handling
  #
  # * The argument is NOT intended to be used on the work items listing page, add it to the exception list below
  #
  # * If removing an argument, consider that existing saved views may contain this argument, and will need to be
  #   migrated
  it 'accepts all WorkItemsResolver filter arguments' do
    resolver_arguments = Resolvers::Namespaces::WorkItemsResolver.arguments.keys
    input_type_arguments = described_class.arguments.keys

    # Arguments that exist in the work items resolver but should NOT be in Types::WorkItems::SavedViews::FilterInputType
    excluded_from_saved_views = %w[
      ids iids includeAncestors includeArchived parentIds parentWildcardId requirementLegacyWidget sort timeframe
      verificationStatusWidget
    ]

    # Arguments that exist in Types::WorkItems::SavedViews::FilterInputType but NOT in the resolver
    # (i.e. saved view-specific filters)
    excluded_from_resolver = %w[fullPath]

    expected_arguments = resolver_arguments - excluded_from_saved_views

    expect(input_type_arguments - excluded_from_resolver).to match_array(expected_arguments)
  end

  describe 'prepare lambdas' do
    it 'prepares or argument by converting to hash' do
      or_argument = described_class.arguments['or']
      input_value = instance_double(Types::WorkItems::SavedViews::UnionedFilterInputType,
        to_h: { author_username: 'test' })

      prepared_value = or_argument.prepare.call(input_value, nil)

      expect(prepared_value).to eq({ author_username: 'test' })
    end

    it 'prepares not argument by converting to hash' do
      not_argument = described_class.arguments['not']
      input_value = instance_double(Types::WorkItems::SavedViews::NegatedFilterInputType,
        to_h: { label_name: 'bug' })

      prepared_value = not_argument.prepare.call(input_value, nil)

      expect(prepared_value).to eq({ label_name: 'bug' })
    end

    it 'prepares state argument and passes through non-locked states' do
      state_argument = described_class.arguments['state']

      prepared_value = state_argument.prepare.call('opened', nil)

      expect(prepared_value).to eq('opened')
    end

    it 'prepares state argument and raises error for locked state' do
      state_argument = described_class.arguments['state']

      expect { state_argument.prepare.call('locked', nil) }
        .to raise_error(Gitlab::Graphql::Errors::ArgumentError, ::Types::IssuableStateEnum::INVALID_LOCKED_MESSAGE)
    end
  end
end
