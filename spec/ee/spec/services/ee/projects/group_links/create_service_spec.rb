require 'spec_helper'

describe Projects::GroupLinks::CreateService, '#execute' do
  let!(:user) { create :user }
  let!(:project) { create :project }
  let!(:group) { create(:group, visibility_level: 0) }
  let(:opts) do
    {
      link_group_access: '30',
      expires_at: nil
    }
  end

  context 'audit events' do
    include_examples 'audit event logging' do
      let(:operation) { create_group_link(user, project, group, opts) }
      let(:fail_condition!) do
        create(:project_group_link, project: project, group: group)
      end
      let(:attributes) do
        {
           author_id: user.id,
           entity_id: group.id,
           entity_type: 'Group',
           details: {
             add: 'project_access',
             as: 'Developer',
             author_name: user.name,
             target_id: project.id,
             target_type: 'Project',
             target_details: project.full_path
           }
         }
      end
    end
  end

  def create_group_link(user, project, group, opts)
    described_class.new(project, user, opts).execute(group)
  end
end
