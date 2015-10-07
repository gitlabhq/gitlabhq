require 'spec_helper'

describe CiStatusHelper do
  include IconsHelper

  let(:success_commit) { double("Ci::Commit", status: 'success') }
  let(:failed_commit) { double("Ci::Commit", status: 'failed') }

  describe 'ci_status_color' do
    it { expect(ci_status_icon(success_commit)).to include('fa-check') }
    it { expect(ci_status_icon(failed_commit)).to include('fa-close') }
  end

  describe 'ci_status_color' do
    it { expect(ci_status_color(success_commit)).to eq('green') }
    it { expect(ci_status_color(failed_commit)).to eq('red') }
  end
end
