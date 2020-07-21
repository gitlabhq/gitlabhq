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

  describe 'packages_coming_soon_enabled?' do
    it 'returns false when the feature flag is disabled' do
      stub_feature_flags(packages_coming_soon: false)

      expect(helper.packages_coming_soon_enabled?(project)).to eq(false)
    end

    it 'returns false when not on dev or gitlab.com' do
      expect(helper.packages_coming_soon_enabled?(project)).to eq(false)
    end
  end

  describe 'packages_coming_soon_data' do
    let_it_be(:group) { create(:group) }

    before do
      allow(Gitlab).to receive(:dev_env_or_com?) { true }
    end

    it 'returns the gitlab project on gitlab.com' do
      allow(Gitlab).to receive(:com?) { true }

      expect(helper.packages_coming_soon_data(project)).to include({ project_path: 'gitlab-org/gitlab' })
    end

    it 'returns the test project when not on gitlab.com' do
      expect(helper.packages_coming_soon_data(project)).to include({ project_path: 'gitlab-org/gitlab-test' })
    end

    it 'works correctly with a group' do
      expect(helper.packages_coming_soon_data(group)).to include({ project_path: 'gitlab-org/gitlab-test' })
    end
  end
end
