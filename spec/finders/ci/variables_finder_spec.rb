# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::VariablesFinder do
  let!(:project) { create(:project) }
  let!(:params) { {} }

  let!(:var1) { create(:ci_variable, project: project, key: 'key1', environment_scope: 'staging') }
  let!(:var2) { create(:ci_variable, project: project, key: 'key2', environment_scope: 'staging') }
  let!(:var3) { create(:ci_variable, project: project, key: 'key2', environment_scope: 'production') }

  describe '#initialize' do
    subject { described_class.new(project, params) }

    context 'without key filter' do
      let!(:params) { {} }

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError, 'Please provide params[:key]')
      end
    end
  end

  describe '#execute' do
    subject { described_class.new(project.reload, params).execute }

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
