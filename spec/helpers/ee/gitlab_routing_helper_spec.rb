require 'spec_helper'

describe EE::GitlabRoutingHelper do
  include ProjectsHelper
  include ApplicationSettingsHelper

  let!(:primary_node) { create(:geo_node, :primary) }
  let(:project) { build_stubbed(:empty_project) }

  describe '#geo_primary_default_url_to_repo' do
    it 'returns an HTTP URL' do
      allow(helper).to receive(:default_clone_protocol).and_return('http')

      result = helper.geo_primary_default_url_to_repo(project)

      expect(result).to start_with('http://')
      expect(result).to eq(helper.geo_primary_http_url_to_repo(project))
    end

    it 'returns an HTTPS URL' do
      primary_node.update_attribute(:schema, 'https')
      allow(helper).to receive(:default_clone_protocol).and_return('https')

      result = helper.geo_primary_default_url_to_repo(project)

      expect(result).to start_with('https://')
      expect(result).to eq(helper.geo_primary_http_url_to_repo(project))
    end

    it 'returns an SSH URL' do
      allow(helper).to receive(:default_clone_protocol).and_return('ssh')

      result = helper.geo_primary_default_url_to_repo(project)

      expect(result).to start_with('git@')
      expect(result).to eq(helper.geo_primary_ssh_url_to_repo(project))
    end
  end
end
