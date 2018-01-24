require 'spec_helper'

describe Groups::DestroyService do
  let!(:user) { create(:user) }
  let!(:group) { create(:group) }

  subject { described_class.new(group, user, {}) }

  context 'audit events' do
    include_examples 'audit event logging' do
      let(:operation) { subject.execute }
      let(:fail_condition!) do
        expect_any_instance_of(Group)
          .to receive(:destroy).and_return(group)
      end
      let(:attributes) do
        {
           author_id: user.id,
           entity_id: group.id,
           entity_type: 'Group',
           details: {
             remove: 'group',
             author_name: user.name,
             target_id: group.full_path,
             target_type: 'Group',
             target_details: group.full_path
           }
         }
      end
    end
  end
end
