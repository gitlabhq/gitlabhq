# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackagesHelper do
  let_it_be(:base_url) { "#{Gitlab.config.gitlab.url}/api/v4/" }
  let_it_be(:project) { create(:project) }

  describe 'package_registry_instance_url' do
    it 'returns conant instance url when registry_type is conant' do
      url = helper.package_registry_instance_url(:conan)

      expect(url).to eq("#{base_url}packages/conan")
    end

    it 'returns npm instance url when registry_type is npm' do
      url = helper.package_registry_instance_url(:npm)

      expect(url).to eq("#{base_url}packages/npm")
    end
  end

  describe 'package_registry_project_url' do
    it 'returns maven registry url when registry_type is not provided' do
      url = helper.package_registry_project_url(1)

      expect(url).to eq("#{base_url}projects/1/packages/maven")
    end

    it 'returns specified registry url when registry_type is provided' do
      url = helper.package_registry_project_url(1, :npm)

      expect(url).to eq("#{base_url}projects/1/packages/npm")
    end
  end

  describe 'pypi_registry_url' do
    let_it_be(:base_url_with_token) { base_url.sub('://', '://__token__:<your_personal_token>@') }

    it 'returns the pypi registry url' do
      url = helper.pypi_registry_url(1)

      expect(url).to eq("#{base_url_with_token}projects/1/packages/pypi/simple")
    end
  end

  describe 'composer_registry_url' do
    it 'return the composer registry url' do
      url = helper.composer_registry_url(1)

      expect(url).to eq("#{base_url}group/1/-/packages/composer/packages.json")
    end
  end

  describe 'composer_config_repository_name' do
    let(:host) { Gitlab.config.gitlab.host }
    let(:group_id) { 1 }

    it 'return global unique composer registry id' do
      id = helper.composer_config_repository_name(group_id)

      expect(id).to eq("#{host}/#{group_id}")
    end
  end
end
