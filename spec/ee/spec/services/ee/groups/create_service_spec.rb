require 'spec_helper'

describe Groups::CreateService, '#execute' do
  let!(:user) { create :user }
  let!(:opts) do
    {
      name: 'GitLab',
      path: 'group_path',
      visibility_level: Gitlab::VisibilityLevel::PUBLIC
    }
  end

  context 'audit events' do
    include_examples 'audit event logging' do
      let(:operation) { create_group(user, opts) }
      let(:fail_condition!) do
        allow(Gitlab::VisibilityLevel).to receive(:allowed_for?).and_return(false)
      end
      let(:attributes) do
        {
           author_id: user.id,
           entity_id: @resource.id,
           entity_type: 'Group',
           details: {
             add: 'group',
             author_name: user.name,
             target_id: @resource.full_path,
             target_type: 'Group',
             target_details: @resource.full_path
           }
         }
      end
    end
  end

  def create_group(user, opts)
    described_class.new(user, opts).execute
  end
end
