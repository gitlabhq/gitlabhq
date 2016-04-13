require 'spec_helper'

describe CiStatusHelper do
  include IconsHelper

  let(:success_commit) { double("Ci::Commit", status: 'success') }
  let(:failed_commit) { double("Ci::Commit", status: 'failed') }

  describe 'ci_icon_for_status' do
    it { expect(helper.ci_icon_for_status(success_commit.status)).to include('fa-check') }
    it { expect(helper.ci_icon_for_status(failed_commit.status)).to include('fa-close') }
  end
end
