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
  end
end
