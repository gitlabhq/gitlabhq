require 'spec_helper'

describe Groups::UpdateService, '#execute' do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, :public) }

  context 'audit events' do
    let(:audit_event_params) do
      {
        author_id: user.id,
        entity_id: group.id,
        entity_type: 'Group',
        details: {
          author_name: user.name,
          target_id: group.id,
          target_type: 'Group',
          target_details: group.full_path
        }
      }
    end

    context '#visibility' do
      before do
        group.add_owner(user)
      end

      include_examples 'audit event logging' do
        let(:operation) do
          update_group(group, user, visibility_level: Gitlab::VisibilityLevel::PRIVATE)
        end
        let(:fail_condition!) do
          allow(group).to receive(:save).and_return(false)
        end

        let(:attributes) do
          audit_event_params.tap do |param|
            param[:details].merge!(
              change: 'visibility',
              from: 'Public',
              to: 'Private'
            )
          end
        end
      end
    end
  end

  def update_group(group, user, opts)
    Groups::UpdateService.new(group, user, opts).execute
  end
end
