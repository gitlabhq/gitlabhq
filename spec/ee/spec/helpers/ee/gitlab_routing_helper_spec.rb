require 'spec_helper'

describe EE::GitlabRoutingHelper do
  include ProjectsHelper
  include ApplicationSettingsHelper

  set(:primary) { create(:geo_node, :primary, url: 'http://localhost:123/relative', clone_url_prefix: 'git@localhost:') }
  set(:group) { create(:group, path: 'foo') }
  set(:project) { create(:project, namespace: group, path: 'bar') }

  describe '#geo_primary_web_url' do
    before do
      allow(helper).to receive(:default_clone_protocol).and_return('http')
    end

    it 'generates a path to the project' do
      result = helper.geo_primary_web_url(project)

      expect(result).to eq('http://localhost:123/relative/foo/bar')
    end

    it 'generates a path to the wiki' do
      result = helper.geo_primary_web_url(project.wiki)

      expect(result).to eq('http://localhost:123/relative/foo/bar.wiki')
    end
  end

  describe '#geo_primary_default_url_to_repo' do
    subject { helper.geo_primary_default_url_to_repo(repo) }

    context 'HTTP' do
      before do
        allow(helper).to receive(:default_clone_protocol).and_return('http')
        primary.update!(schema: 'http')
      end

      context 'project' do
        let(:repo) { project }

        it { is_expected.to eq('http://localhost:123/relative/foo/bar.git') }
      end

      context 'wiki' do
        let(:repo) { project.wiki }

        it { is_expected.to eq('http://localhost:123/relative/foo/bar.wiki.git') }
      end
    end

    context 'HTTPS' do
      before do
        allow(helper).to receive(:default_clone_protocol).and_return('https')
        primary.update!(schema: 'https')
      end

      context 'project' do
        let(:repo) { project }

        it { is_expected.to eq('https://localhost:123/relative/foo/bar.git') }
      end

      context 'wiki' do
        let(:repo) { project.wiki }

        it { is_expected.to eq('https://localhost:123/relative/foo/bar.wiki.git') }
      end
    end

    context 'SSH' do
      before do
        allow(helper).to receive(:default_clone_protocol).and_return('ssh')
      end

      context 'project' do
        let(:repo) { project }

        it { is_expected.to eq('git@localhost:foo/bar.git') }
      end

      context 'wiki' do
        let(:repo) { project.wiki }

        it { is_expected.to eq('git@localhost:foo/bar.wiki.git') }
      end
    end
  end
end
