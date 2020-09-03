# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelinesHelper do
  include Devise::Test::ControllerHelpers

  describe 'pipeline_warnings' do
    let(:pipeline) { double(:pipeline, warning_messages: warning_messages) }

    subject { helper.pipeline_warnings(pipeline) }

    context 'when pipeline has no warnings' do
      let(:warning_messages) { [] }

      it 'is empty' do
        expect(subject).to be_nil
      end
    end

    context 'when pipeline has warnings' do
      let(:warning_messages) { [double(content: 'Warning 1'), double(content: 'Warning 2')] }

      it 'returns a warning callout box' do
        expect(subject).to have_css 'div.bs-callout-warning'
        expect(subject).to include '2 warning(s) found:'
      end

      it 'lists the the warnings' do
        expect(subject).to include 'Warning 1'
        expect(subject).to include 'Warning 2'
      end
    end
  end

  describe 'warning_header' do
    subject { helper.warning_header(count) }

    context 'when warnings are more than max cap' do
      let(:count) { 30 }

      it 'returns 30 warning(s) found: showing first 25' do
        expect(subject).to eq('30 warning(s) found: showing first 25')
      end
    end

    context 'when warnings are less than max cap' do
      let(:count) { 15 }

      it 'returns 15 warning(s) found' do
        expect(subject).to eq('15 warning(s) found:')
      end
    end
  end
end
