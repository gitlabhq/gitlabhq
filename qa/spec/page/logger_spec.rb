# frozen_string_literal: true

require 'capybara/dsl'

describe QA::Support::Page::Logging do
  let(:page) { double().as_null_object }

  before do
    allow(Capybara).to receive(:current_session).and_return(page)
    allow(page).to receive(:current_url).and_return('a page')
    allow(page).to receive(:has_css?).with(any_args).and_return(true)
    allow(QA::Runtime::Env).to receive(:debug?).and_return(true)
  end

  subject { QA::Page::Base.new }

  it 'logs refresh' do
    expect { subject.refresh }
      .to output(/refreshing a page/).to_stdout_from_any_process
  end

  it 'logs wait' do
    expect { subject.wait(max: 0) {} }
      .to output(/with wait/).to_stdout_from_any_process
    expect { subject.wait(max: 0) {} }
      .to output(/end wait/).to_stdout_from_any_process
  end

  it 'logs scroll_to' do
    expect { subject.scroll_to(:element) }
      .to output(/scrolling to :element/).to_stdout_from_any_process
  end

  it 'logs asset_exists?' do
    expect { subject.asset_exists?('a url') }
      .to output(/asset_exists\? a url returned false/).to_stdout_from_any_process
  end

  it 'logs find_element' do
    expect { subject.find_element(:element) }
      .to output(/found :element/).to_stdout_from_any_process
  end

  it 'logs all_elements' do
    expect { subject.all_elements(:element) }
      .to output(/finding all :element/).to_stdout_from_any_process
  end

  it 'logs click_element' do
    expect { subject.click_element(:element) }
      .to output(/clicking :element/).to_stdout_from_any_process
  end

  it 'logs fill_element' do
    expect { subject.fill_element(:element, 'foo') }
      .to output(/filling :element with "foo"/).to_stdout_from_any_process
  end

  it 'logs has_element?' do
    expect { subject.has_element?(:element) }
      .to output(/has_element\? :element returned true/).to_stdout_from_any_process
  end

  it 'logs within_element' do
    expect { subject.within_element(:element) }
      .to output(/within element :element/).to_stdout_from_any_process
    expect { subject.within_element(:element) }
      .to output(/end within element :element/).to_stdout_from_any_process
  end
end
