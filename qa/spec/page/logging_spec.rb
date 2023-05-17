# frozen_string_literal: true

require 'capybara/dsl'

RSpec.describe QA::Support::Page::Logging do
  let(:page) { double.as_null_object }
  let(:logger) { Gitlab::QA::TestLogger.logger(level: ::Logger::DEBUG, source: 'QA Tests') }
  let(:page_class) { class_double('QA::Page::TestPage') }

  before do
    allow(QA::Runtime::Logger).to receive(:logger).and_return(logger)

    allow(Capybara).to receive(:current_session).and_return(page)
    allow(page).to receive(:find).and_return(page)
    allow(page).to receive(:current_url).and_return('http://current-url')
    allow(page).to receive(:has_css?).with(any_args).and_return(true)
    allow(QA::Support::PageErrorChecker).to receive(:check_page_for_error_code).and_return(0)
  end

  subject do
    Class.new(QA::Page::Base) do
      prepend QA::Support::Page::Logging
    end.new
  end

  it 'logs refresh' do
    expect { subject.refresh }
      .to output(%r{refreshing http://current-url}).to_stdout_from_any_process
  end

  it 'logs scroll_to' do
    expect { subject.scroll_to(:element) }
      .to output(/scrolling to :element/).to_stdout_from_any_process
  end

  it 'logs asset_exists?' do
    expect { subject.asset_exists?('http://asset-url') }
      .to output(%r{asset_exists\? http://asset-url returned false}).to_stdout_from_any_process
  end

  it 'logs find_element' do
    expect { subject.find_element(:element) }
      .to output(/finding :element/).to_stdout_from_any_process
    expect { subject.find_element(:element) }
      .to output(/found :element/).to_stdout_from_any_process
  end

  it 'logs find_element with text' do
    expect { subject.find_element(:element, text: 'foo') }
      .to output(/finding :element with args {:text=>"foo"}/).to_stdout_from_any_process
    expect { subject.find_element(:element, text: 'foo') }
      .to output(/found :element/).to_stdout_from_any_process
  end

  it 'logs find_element with wait' do
    expect { subject.find_element(:element, wait: 0) }
      .to output(/finding :element with args {:wait=>0}/).to_stdout_from_any_process
  end

  it 'logs find_element with class' do
    expect { subject.find_element(:element, class: 'active') }
      .to output(/finding :element with args {:class=>"active"}/).to_stdout_from_any_process
  end

  it 'logs a warning if find_element is slow' do
    starting = Time.now
    ending = starting + 1.4
    expected_msg = /Potentially Slow Code 'find_element element' took 1.4s/

    # verify logs a warning message to indicate potentially slow code lookups
    expect { subject.find_element(:element, starting_time: starting, ending_time: ending) }
      .to output(expected_msg).to_stdout_from_any_process

    # verify it doesn't log a warning message if within allowed limits
    expect { subject.find_element(:element, starting_time: starting, ending_time: ending, log_slow_threshold: 1.5) }
      .not_to output(expected_msg).to_stdout_from_any_process
  end

  it 'logs click_element' do
    expect { subject.click_element(:element) }
      .to output(/clicking :element/).to_stdout_from_any_process
  end

  it 'logs click_element with a page' do
    allow(page_class).to receive(:validate_elements_present!).and_return(true)
    allow(page_class).to receive(:to_s).and_return('QA::Page::TestPage')

    expect { subject.click_element(:element, page_class) }
      .to output(/clicking :element and ensuring QA::Page::TestPage is present/).to_stdout_from_any_process
  end

  it 'logs fill_element' do
    expect { subject.fill_element(:element, 'foo') }
      .to output(/filling :element with "foo"/).to_stdout_from_any_process
  end

  it 'logs has_element?' do
    expect { subject.has_element?(:element) }.to output(
      /has_element\? :element \(wait: #{Capybara.default_max_wait_time}\) returned: true/o
    ).to_stdout_from_any_process
  end

  it 'logs has_element? with text' do
    expect { subject.has_element?(:element, text: "some text") }.to output(
      /has_element\? :element with text "some text" \(wait: #{Capybara.default_max_wait_time}\) returned: true/o
    ).to_stdout_from_any_process
  end

  it 'logs has_no_element?' do
    allow(page).to receive(:has_no_css?).and_return(true)

    expect { subject.has_no_element?(:element) }.to output(
      /has_no_element\? :element \(wait: #{Capybara.default_max_wait_time}\) returned: true/o
    ).to_stdout_from_any_process
  end

  it 'logs has_no_element? with text' do
    allow(page).to receive(:has_no_css?).and_return(true)

    expect { subject.has_no_element?(:element, text: "more text") }.to output(
      /has_no_element\? :element with text "more text" \(wait: #{Capybara.default_max_wait_time}\) returned: true/o
    ).to_stdout_from_any_process
  end

  it 'logs has_text?' do
    allow(page).to receive(:has_text?).and_return(true)

    expect { subject.has_text? 'foo' }.to output(
      /has_text\?\('foo', wait: #{Capybara.default_max_wait_time}\) returned true/o
    ).to_stdout_from_any_process
  end

  it 'logs has_no_text?' do
    allow(page).to receive(:has_no_text?).with('foo', any_args).and_return(true)

    expect { subject.has_no_text? 'foo' }.to output(
      /has_no_text\?\('foo', wait: #{Capybara.default_max_wait_time}\) returned true/o
    ).to_stdout_from_any_process
  end

  it 'logs finished_loading?' do
    expect { subject.finished_loading? }
      .to output(/waiting for loading to complete\.\.\./).to_stdout_from_any_process
  end

  it 'logs within_element' do
    expect { subject.within_element(:element, text: nil) }
      .to output(/within element :element/).to_stdout_from_any_process
    expect { subject.within_element(:element, text: nil) }
      .to output(/end within element :element/).to_stdout_from_any_process
  end

  context 'with all_elements' do
    it 'logs the number of elements found' do
      allow(page).to receive(:all).and_return([1, 2])

      expect { subject.all_elements(:element, count: 2) }
        .to output(/finding all :element/).to_stdout_from_any_process
      expect { subject.all_elements(:element, count: 2) }
        .to output(/found 2 :element/).to_stdout_from_any_process
    end

    it 'logs 0 if no elements are found' do
      allow(page).to receive(:all).and_return([])

      expect { subject.all_elements(:element, count: 1) }
        .to output(/finding all :element/).to_stdout_from_any_process
      expect { subject.all_elements(:element, count: 1) }
        .not_to output(/found 0 :elements/).to_stdout_from_any_process
    end
  end
end
