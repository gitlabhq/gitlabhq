require 'rails_helper'

describe 'Merge request > User uses quick actions', :js do
  include Spec::Support::Helpers::Features::NotesHelpers

  describe 'merge-request-only commands' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project) }

    before do
      project.add_maintainer(user)
    end

    describe 'adding a weight from a note' do
      before do
        sign_in(user)
        visit project_merge_request_path(project, merge_request)
      end

      it 'does not recognize the command nor create a note' do
        add_note("/weight 5")

        expect(page).not_to have_content '/weight 5'
      end
    end
  end
end
