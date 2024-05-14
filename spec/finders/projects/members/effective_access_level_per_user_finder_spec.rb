# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Projects::Members::EffectiveAccessLevelPerUserFinder, '#execute' do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }

  # The result set is being converted to json just for the ease of testing.
  subject { described_class.new(project, user).execute.as_json }

  context 'a combination of all possible avenues of membership' do
    let_it_be(:another_user) { create(:user) }
    let_it_be(:shared_with_group) { create(:group) }

    before do
      create(:project_group_link, :maintainer, project: project, group: shared_with_group)
      create(:group_group_link, :reporter, shared_group: project.group, shared_with_group: shared_with_group)

      shared_with_group.add_maintainer(user)
      shared_with_group.add_maintainer(another_user)
      group.add_guest(user)
      group.add_guest(another_user)
      project.add_developer(user)
      project.add_developer(another_user)
    end

    it 'includes the highest access level from all avenues of memberships for the specific user alone' do
      expect(subject.first).to match(hash_including(
        {
          'user_id' => user.id,
          'access_level' => Gitlab::Access::MAINTAINER, # From project_group_link
          'id' => nil
        }
      ))
    end
  end
end
