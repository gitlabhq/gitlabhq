# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TriggersHelper do
  let(:project_id) { 1 }

  describe '.builds_trigger_url' do
    subject { helper.builds_trigger_url(project_id, ref: ref) }

    context 'with no ref' do
      let(:ref) { nil }

      specify { expect(subject).to eq "#{Settings.gitlab.url}/api/v4/projects/1/trigger/pipeline" }
    end

    context 'with ref' do
      let(:ref) { 'master' }

      specify { expect(subject).to eq "#{Settings.gitlab.url}/api/v4/projects/1/ref/master/trigger/pipeline" }
    end
  end

  describe '.service_trigger_url' do
    subject { helper.service_trigger_url(service) }

    let(:service) { double(project_id: 1, to_param: 'param') }

    specify { expect(subject).to eq "#{Settings.gitlab.url}/api/v4/projects/1/services/param/trigger" }
  end
end
