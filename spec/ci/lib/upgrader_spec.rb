require 'spec_helper'

describe Upgrader do
  let(:upgrader) { Upgrader.new }
  let(:current_version) { GitlabCi::VERSION }

  describe 'current_version_raw' do
    it { upgrader.current_version_raw.should == current_version }
  end

  describe 'latest_version?' do
    it 'should be true if newest version' do
      upgrader.stub(latest_version_raw: current_version)
      upgrader.latest_version?.should be_true
    end
  end

  describe 'latest_version_raw' do
    it 'should be latest version for GitlabCI 3' do
        allow(upgrader).to receive(:current_version_raw).and_return('3.0.0')
        expect(upgrader.latest_version_raw).to eq('v3.2.0')
    end

    it 'should get the latest version from tags' do
        allow(upgrader).to receive(:fetch_git_tags).and_return([
            '1b5bee25b51724214c7a3307ef94027ab93ec982  refs/tags/v7.8.1',
            '424cb42e35947fa304ef83eb211ffc657e31aef3  refs/tags/v7.8.1^{}',
            '498e5ba63be1bb99e30c6e720902d864aac4413c  refs/tags/v7.9.0.rc1',
            '96aaf45ae93bd43e8b3f5d4d353d64d3cbe1e63b  refs/tags/v7.9.0.rc1^{}',
            '94aaf45ae93bd43e8b3fad4a353d64d3cbe1e62b  refs/tags/v7.1.0',
            '96aaf45ae93ba13e8b3f5d4d353d64d3cbe1e251  refs/tags/v7.1.0^{}',
            '29359d64442bf54b4ca1d8b439fd9e5f9cd83252  refs/tags/v7.10.0',
            '4d9213a6378bff43a69ae099702fb81e29335e7a  refs/tags/v7.10.0^{}',
            '1d93e1626bda93622ca7a2ae2825e2e94dabf3c6  refs/tags/v7.12.0',
            '0188a9d1c2efdc52bfad36ad303686be997de713  refs/tags/v7.12.0^{}'])
        expect(upgrader.latest_version_raw).to eq("v7.12.0")
    end
  end
end
