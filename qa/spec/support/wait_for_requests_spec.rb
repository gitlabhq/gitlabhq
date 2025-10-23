# frozen_string_literal: true

RSpec.describe QA::Support::WaitForRequests do
  describe '.wait_for_requests' do
    before do
      allow(subject).to receive(:finished_all_ajax_requests?).and_return(true)
      allow(subject).to receive(:spinner_cleared?).and_return(true)
      allow(QA::Support::PageErrorChecker).to receive(:check_page_for_error_code)
      allow(QA::Support::Waiter).to receive(:wait_until).and_yield
    end

    context 'when skip_spinner_check is defaulted to true' do
      it 'does not call spinner_cleared?' do
        subject.wait_for_requests
        expect(subject).not_to have_received(:spinner_cleared?)
      end
    end

    context 'when skip_spinner_check is set to false' do
      it 'calls spinner_cleared?' do
        subject.wait_for_requests(skip_spinner_check: false)

        expect(subject).to have_received(:spinner_cleared?).with(hash_including(wait: 1))
      end
    end

    context 'when only AJAX requests did not load in time' do
      before do
        allow(subject).to receive(:finished_all_ajax_requests?).and_return(false)
        allow(QA::Support::Waiter).to receive(:wait_until).and_yield
          .and_raise(QA::Support::Repeater::WaitExceededError.new('Wait exceeded'))
      end

      it 'raises and logs the error that requests failed to complete' do
        expect { subject.wait_for_requests(skip_spinner_check: false) }.to raise_error(
          QA::Support::Repeater::WaitExceededError,
          'Page did not fully load: AJAX requests pending (spinner check passed)'
        )
      end
    end

    context 'when spinner check fails' do
      before do
        allow(subject).to receive(:spinner_cleared?).and_return(false)
        allow(QA::Support::Waiter).to receive(:wait_until).and_yield
          .and_raise(QA::Support::Repeater::WaitExceededError.new('Wait exceeded'))
      end

      it 'raises and logs the error that .gl-spinner is still visible' do
        expect { subject.wait_for_requests(skip_spinner_check: false) }.to raise_error(
          QA::Support::Repeater::WaitExceededError,
          'Page did not fully load: Spinner still visible (AJAX requests completed)'
        )
      end
    end

    context 'when both AJAX requests and spinner check fails' do
      before do
        allow(subject).to receive(:spinner_cleared?).and_return(false)
        allow(subject).to receive(:finished_all_ajax_requests?).and_return(false)
        allow(QA::Support::Waiter).to receive(:wait_until).and_yield
          .and_raise(QA::Support::Repeater::WaitExceededError.new('Wait exceeded'))
      end

      it 'raises and logs the error that both checks failed' do
        expect { subject.wait_for_requests(skip_spinner_check: false) }.to raise_error(
          QA::Support::Repeater::WaitExceededError,
          'Page did not fully load: AJAX requests pending and spinner is still visible'
        )
      end
    end

    context 'when both AJAX requests and spinner pass' do
      before do
        allow(subject).to receive(:spinner_cleared?).and_return(true)
        allow(subject).to receive(:finished_all_ajax_requests?).and_return(true)
      end

      it 'throws no error' do
        expect { subject.wait_for_requests(skip_spinner_check: false) }.not_to raise_error
      end
    end

    context 'when spinner element is stale' do
      before do
        allow(subject).to receive(:spinner_cleared?).and_call_original
        allow(QA::Runtime::Logger).to receive(:error)
      end

      it 'rescues StaleElementReferenceError and logs error' do
        stale_error = Selenium::WebDriver::Error::StaleElementReferenceError.new('element is stale')
        allow(Capybara.page).to receive(:has_no_css?).and_raise(stale_error)

        subject.spinner_cleared?

        expect(QA::Runtime::Logger).to have_received(:error)
          .with(a_string_matching(/\.gl-spinner reference has become stale/))
      end
    end

    context 'when AJAX fails and spinner check is skipped' do
      before do
        allow(subject).to receive(:finished_all_ajax_requests?).and_return(false)
        allow(QA::Support::Waiter).to receive(:wait_until).and_yield
          .and_raise(QA::Support::Repeater::WaitExceededError.new('Wait exceeded'))
      end

      it 'raises and logs that AJAX requests are still pending' do
        expect { subject.wait_for_requests(skip_spinner_check: true) }.to raise_error(
          QA::Support::Repeater::WaitExceededError,
          'Page did not fully load after 60 seconds due to pending AJAX requests'
        )
      end
    end
  end
end
