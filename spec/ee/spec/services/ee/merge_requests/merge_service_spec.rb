require 'spec_helper'

describe MergeRequests::MergeService do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request, :simple) }
  let(:project) { merge_request.project }

  before do
    project.add_master(user)
  end

  describe '#execute' do
    context 'project has exceeded size limit' do
      let(:service) { described_class.new(project, user, commit_message: 'Awesome message') }

      before do
        allow(project).to receive(:above_size_limit?).and_return(true)

        perform_enqueued_jobs do
          service.execute(merge_request)
        end
      end

      it 'returns the correct error message' do
        expect(merge_request.merge_error).to include('This merge request cannot be merged')
      end
    end
  end
end
