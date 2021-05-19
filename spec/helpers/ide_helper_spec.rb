# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IdeHelper do
  describe '#ide_data' do
    let_it_be(:project) { create(:project) }

    before do
      allow(helper).to receive(:current_user).and_return(project.creator)
    end

    context 'when instance vars are not set' do
      it 'returns instance data in the hash as nil' do
        expect(helper.ide_data)
          .to include(
            'branch-name' => nil,
            'file-path' => nil,
            'merge-request' => nil,
            'fork-info' => nil,
            'project' => nil
          )
      end
    end

    context 'when instance vars are set' do
      it 'returns instance data in the hash' do
        fork_info = { ide_path: '/test/ide/path' }

        self.instance_variable_set(:@branch, 'master')
        self.instance_variable_set(:@path, 'foo/bar')
        self.instance_variable_set(:@merge_request, '1')
        self.instance_variable_set(:@fork_info, fork_info)
        self.instance_variable_set(:@project, project)

        serialized_project = API::Entities::Project.represent(project).to_json

        expect(helper.ide_data)
          .to include(
            'branch-name' => 'master',
            'file-path' => 'foo/bar',
            'merge-request' => '1',
            'fork-info' => fork_info.to_json,
            'project' => serialized_project
          )
      end
    end

    context 'environments guidance experiment', :experiment do
      before do
        stub_experiments(in_product_guidance_environments_webide: :candidate)
        self.instance_variable_set(:@project, project)
      end

      context 'when project has no enviornments' do
        it 'enables environment guidance' do
          expect(helper.ide_data).to include('enable-environments-guidance' => 'true')
        end

        context 'and the callout has been dismissed' do
          it 'disables environment guidance' do
            callout = create(:user_callout, feature_name: :web_ide_ci_environments_guidance, user: project.creator)
            callout.update!(dismissed_at: Time.now - 1.week)
            allow(helper).to receive(:current_user).and_return(User.find(project.creator.id))
            expect(helper.ide_data).to include('enable-environments-guidance' => 'false')
          end
        end
      end

      context 'when the project has environments' do
        it 'disables environment guidance' do
          create(:environment, project: project)

          expect(helper.ide_data).to include('enable-environments-guidance' => 'false')
        end
      end
    end
  end
end
