require 'spec_helper'

describe CiStatusHelper do
  include IconsHelper

  let(:success_commit) { double("Ci::Commit", status: 'success') }
  let(:failed_commit) { double("Ci::Commit", status: 'failed') }

  describe 'ci_status_icon' do
    it { expect(helper.ci_status_icon(success_commit)).to include('fa-check') }
    it { expect(helper.ci_status_icon(failed_commit)).to include('fa-close') }
  end
end
