require 'spec_helper'

describe Projects::CreateService, benchmark: true do
  describe '#execute' do
    let(:user) { create(:user, :admin) }

    let(:group) do
      group = create(:group)

      create(:group_member, group: group, user: user)

      group
    end

    benchmark_subject do
      name    = SecureRandom.hex
      service = described_class.new(user,
                                    name:             name,
                                    path:             name,
                                    namespace_id:     group.id,
                                    visibility_level: Gitlab::VisibilityLevel::PUBLIC)

      service.execute
    end

    it { is_expected.to iterate_per_second(0.5) }
  end
end
