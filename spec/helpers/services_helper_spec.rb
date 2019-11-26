# frozen_string_literal: true

require 'spec_helper'

describe ServicesHelper do
  describe 'event_action_title' do
    it { expect(event_action_title('comment')).to eq 'Comment' }
    it { expect(event_action_title('something')).to eq 'Something' }
  end

  describe 'event_action_description' do
    it { expect(event_action_description('comment')).to eq 'Comment will be posted on each event' }
    it { expect(event_action_description('something')).to eq nil }
  end
end
