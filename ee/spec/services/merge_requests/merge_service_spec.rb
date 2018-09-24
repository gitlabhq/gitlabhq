require 'spec_helper'

describe MergeRequests::MergeService do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request, :simple) }
  let(:project) { merge_request.project }

  before do
    project.add_maintainer(user)
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

  describe '#hooks_validation_pass?' do
    shared_examples 'hook validations are skipped when push rules unlicensed' do
      subject { service.hooks_validation_pass?(merge_request) }

      before do
        stub_licensed_features(push_rules: false)
      end

      it { is_expected.to be_truthy }
    end

    let(:service) { described_class.new(project, user, commit_message: 'Awesome message') }

    it 'returns true when valid' do
      expect(service.hooks_validation_pass?(merge_request)).to be_truthy
    end

    context 'commit message validation for required characters' do
      before do
        allow(project).to receive(:push_rule) { build(:push_rule, commit_message_regex: 'unmatched pattern .*') }
      end

      it_behaves_like 'hook validations are skipped when push rules unlicensed'

      it 'returns false and saves error when invalid' do
        expect(service.hooks_validation_pass?(merge_request)).to be_falsey
        expect(merge_request.merge_error).not_to be_empty
      end
    end

    context 'commit message validation for forbidden characters' do
      before do
        allow(project).to receive(:push_rule) { build(:push_rule, commit_message_negative_regex: '.*') }
      end

      it_behaves_like 'hook validations are skipped when push rules unlicensed'

      it 'returns false and saves error when invalid' do
        expect(service.hooks_validation_pass?(merge_request)).to be_falsey
        expect(merge_request.merge_error).not_to be_empty
      end
    end

    context 'authors email validation' do
      before do
        allow(project).to receive(:push_rule) { build(:push_rule, author_email_regex: '.*@unmatchedemaildomain.com') }
      end

      it_behaves_like 'hook validations are skipped when push rules unlicensed'

      it 'returns false and saves error when invalid' do
        expect(service.hooks_validation_pass?(merge_request)).to be_falsey
        expect(merge_request.merge_error).not_to be_empty
      end

      it 'validates against the commit email' do
        user.commit_email = 'foo@unmatchedemaildomain.com'

        expect(service.hooks_validation_pass?(merge_request)).to be_truthy
      end
    end

    context 'fast forward merge request' do
      it 'returns true when fast forward is enabled' do
        allow(project).to receive(:merge_requests_ff_only_enabled) { true }

        expect(service.hooks_validation_pass?(merge_request)).to be_truthy
      end
    end
  end
end
