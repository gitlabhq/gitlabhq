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
        expect(subject).to have_css 'div.alert-warning'
        expect(subject).to include 'Warning:'
      end

      it 'lists the the warnings' do
        expect(subject).to include 'Warning 1'
        expect(subject).to include 'Warning 2'
      end
    end
  end
end
