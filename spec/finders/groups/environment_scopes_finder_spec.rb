# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::EnvironmentScopesFinder, feature_category: :ci_variables do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group, :public) }

    let!(:environment1) { create(:ci_group_variable, group: group, key: 'var1', environment_scope: 'environment1') }
    let!(:environment2) { create(:ci_group_variable, group: group, key: 'var2', environment_scope: 'environment2') }
    let!(:environment3) { create(:ci_group_variable, group: group, key: 'var2', environment_scope: 'environment3') }
    let(:finder) { described_class.new(group: group, params: params) }

    subject { finder.execute }

    context 'with default no arguments' do
      let(:params) { {} }

      it do
        expected_result = group.variables.environment_scope_names

        expect(subject.map(&:name))
          .to match_array(expected_result)
      end
    end

    context 'with search' do
      let(:params) { { search: 'ment1' } }

      it do
        expected_result = ['environment1']

        expect(subject.map(&:name))
          .to match_array(expected_result)
      end
    end

    context 'with specific name' do
      let(:params) { { name: 'environment3' } }

      it do
        expect(subject.map(&:name))
          .to match_array([environment3.environment_scope])
      end
    end
  end
end
