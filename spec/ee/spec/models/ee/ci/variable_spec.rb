require 'spec_helper'

describe Ci::Variable do
  subject { build(:ci_variable) }

  it { is_expected.to allow_value('*').for(:environment_scope) }
  it { is_expected.to allow_value('review/*').for(:environment_scope) }
  it { is_expected.not_to allow_value('').for(:environment_scope) }

  it do
    is_expected.to validate_uniqueness_of(:key)
      .scoped_to(:project_id, :environment_scope)
  end

  describe '#environment_scope=' do
    context 'when the new environment_scope is nil' do
      it 'strips leading and trailing whitespaces' do
        subject.environment_scope = nil

        expect(subject.environment_scope).to eq('')
      end
    end

    context 'when the new environment_scope has leadind and trailing whitespaces' do
      it 'strips leading and trailing whitespaces' do
        subject.environment_scope = ' * '

        expect(subject.environment_scope).to eq('*')
      end
    end
  end
end
