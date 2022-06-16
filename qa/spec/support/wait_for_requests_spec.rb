# frozen_string_literal: true

RSpec.describe QA::Support::WaitForRequests do
  describe '.wait_for_requests' do
    before do
      allow(subject).to receive(:finished_all_ajax_requests?).and_return(true)
      allow(subject).to receive(:finished_loading?).and_return(true)
      allow(QA::Support::PageErrorChecker).to receive(:check_page_for_error_code)
    end

    context 'when skip_finished_loading_check is defaulted to false' do
      it 'calls finished_loading?' do
        subject.wait_for_requests

        expect(subject).to have_received(:finished_loading?).with(hash_including(wait: 1))
      end
    end

    context 'when skip_resp_code_check is true' do
      it 'does not parse for an error code' do
        subject.wait_for_requests(skip_resp_code_check: true)

        expect(QA::Support::PageErrorChecker).not_to have_received(:check_page_for_error_code)
      end
    end
  end
end
