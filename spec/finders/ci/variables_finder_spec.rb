# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::VariablesFinder do
  shared_examples 'scoped variables' do
    describe '#initialize' do
      subject { described_class.new(owner, params) }

      context 'without key filter' do
        let!(:params) { {} }

        it 'raises an error' do
          expect { subject }.to raise_error(ArgumentError, 'Please provide params[:key]')
        end
      end
    end

    describe '#execute' do
      subject { described_class.new(owner.reload, params).execute }

      context 'with key filter' do
        let!(:params) { { key: 'key1' } }

        it 'returns var1' do
          expect(subject).to contain_exactly(var1)
        end
      end

      context 'with key and environment_scope filter' do
        let!(:params) { { key: 'key2', filter: { environment_scope: 'staging' } } }

        it 'returns var2' do
          expect(subject).to contain_exactly(var2)
        end
      end
    end
  end

  context 'for a project' do
    let(:owner) { create(:project) }

    let!(:var1) { create(:ci_variable, project: owner, key: 'key1', environment_scope: 'staging') }
    let!(:var2) { create(:ci_variable, project: owner, key: 'key2', environment_scope: 'staging') }
    let!(:var3) { create(:ci_variable, project: owner, key: 'key2', environment_scope: 'production') }

    include_examples 'scoped variables'
  end

  context 'for a group' do
    let(:owner) { create(:group) }

    let!(:var1) { create(:ci_group_variable, group: owner, key: 'key1', environment_scope: 'staging') }
    let!(:var2) { create(:ci_group_variable, group: owner, key: 'key2', environment_scope: 'staging') }
    let!(:var3) { create(:ci_group_variable, group: owner, key: 'key2', environment_scope: 'production') }

    include_examples 'scoped variables'
  end
end
