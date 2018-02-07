require 'spec_helper'

describe VariableEntity do
  let(:variable) { create(:ci_variable) }
  let(:entity) { described_class.new(variable) }

  describe '#as_json' do
    subject { entity.as_json }

    context 'when project has variable environment scopes available' do
      before do
        allow(variable.project).to receive(:feature_available?).with(:variable_environment_scope).and_return(true)
      end

      it 'contains the environment_scope field' do
        expect(subject).to include(:environment_scope)
      end
    end

    context 'when project does not have variable environment scopes available' do
      before do
        allow(variable.project).to receive(:feature_available?).with(:variable_environment_scope).and_return(false)
      end

      it 'does not contain the environment_scope field' do
        expect(subject).not_to include(:environment_scope)
      end
    end
  end
end
