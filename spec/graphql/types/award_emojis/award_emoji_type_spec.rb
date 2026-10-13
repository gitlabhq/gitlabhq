# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AwardEmoji'], feature_category: :team_planning do
  expected_fields = %i[description unicode_version emoji name unicode user]

  specify { expect(described_class.graphql_name).to eq('AwardEmoji') }

  specify { expect(described_class).to require_graphql_authorizations(:read_emoji) }

  specify { expect(described_class).to have_graphql_fields(*expected_fields) }

  describe 'authorization scopes' do
    it 'allows ai_workflows scope token' do
      expect(described_class.authorization_scopes).to include(:ai_workflows)
    end
  end

  describe 'fields with :ai_workflows scope' do
    # Every field must be scoped: all but `emoji` are `null: false`, so an unscoped
    # field would resolve to nil and null out the whole node for these tokens.
    expected_fields.each do |field_name|
      it "includes :ai_workflows scope for the #{field_name} field" do
        field = described_class.fields[field_name.to_s.camelize(:lower)]

        expect(field.instance_variable_get(:@scopes)).to include(:ai_workflows)
      end
    end
  end
end
