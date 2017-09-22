require 'spec_helper'

describe Board do
  context 'validations' do
    context 'when group is present' do
      subject { described_class.new(group: create(:group)) }

      it { is_expected.not_to validate_presence_of(:project) }
      it { is_expected.to validate_presence_of(:group) }
    end

    context 'when project is present' do
      subject { described_class.new(project: create(:project)) }

      it { is_expected.to validate_presence_of(:project) }
      it { is_expected.not_to validate_presence_of(:group) }
    end
  end
end
