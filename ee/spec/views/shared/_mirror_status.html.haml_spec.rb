require 'spec_helper'

describe 'shared/_mirror_status.html.haml' do
  include ApplicationHelper

  context 'when mirror has not updated yet' do
    it 'does not render anything' do
      @project = create(:project, :mirror)

      sign_in(@project.owner)

      render 'shared/mirror_status'

      expect(rendered).to be_empty
    end
  end

  context 'when mirror successful' do
    it 'renders success message' do
      @project = create(:project, :mirror, :import_finished)

      sign_in(@project.owner)

      render 'shared/mirror_status'

      expect(rendered).to have_content("Updated")
    end
  end

  context 'when mirror failed' do
    before do
      @project = create(:project, :mirror, :import_failed)

      sign_in(@project.owner)
    end

    it 'renders failure message' do
      render 'shared/mirror_status', raw_message: true

      expect(rendered).to have_content("The repository failed to update")
    end

    context 'with a previous successful update' do
      it 'renders failure message' do
        @project.mirror_last_successful_update_at = Time.now - 1.minute

        render 'shared/mirror_status', raw_message: true

        expect(rendered).to have_content("Last successful update")
      end
    end

    context 'with a hard failed mirror' do
      it 'renders hard failed message' do
        @project.import_state.retry_count = Gitlab::Mirror::MAX_RETRY + 1

        render 'shared/mirror_status', raw_message: true

        expect(rendered).to have_content("Repository mirroring has been paused due to too many failed attempts, and can be resumed by a project master.")
      end
    end
  end
end
