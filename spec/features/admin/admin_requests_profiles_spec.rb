# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::RequestsProfilesController' do
  let(:tmpdir) { Dir.mktmpdir('profiler-test') }

  before do
    stub_const('Gitlab::RequestProfiler::PROFILES_DIR', tmpdir)
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  after do
    FileUtils.rm_rf(tmpdir)
  end

  describe 'GET /admin/requests_profiles' do
    it 'shows the current profile token' do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)

      visit admin_requests_profiles_path

      expect(page).to have_content("X-Profile-Token: #{Gitlab::RequestProfiler.profile_token}")
    end

    context 'when having multiple profiles' do
      let(:time1) { 1.hour.ago }
      let(:time2) { 2.hours.ago }

      let(:profiles) do
        [
          {
            request_path: '/gitlab-org/gitlab-foss',
            name: "|gitlab-org|gitlab-foss_#{time1.to_i}_execution.html",
            created: time1,
            profile_mode: 'Execution'
          },
          {
            request_path: '/gitlab-org/gitlab-foss',
            name: "|gitlab-org|gitlab-foss_#{time2.to_i}_execution.html",
            created: time2,
            profile_mode: 'Execution'
          },
          {
            request_path: '/gitlab-org/gitlab-foss',
            name: "|gitlab-org|gitlab-foss_#{time1.to_i}_memory.html",
            created: time1,
            profile_mode: 'Memory'
          },
          {
            request_path: '/gitlab-org/gitlab-foss',
            name: "|gitlab-org|gitlab-foss_#{time2.to_i}_memory.html",
            created: time2,
            profile_mode: 'Memory'
          },
          {
            request_path: '/gitlab-org/infrastructure',
            name: "|gitlab-org|infrastructure_#{time1.to_i}_execution.html",
            created: time1,
            profile_mode: 'Execution'
          },
          {
            request_path: '/gitlab-org/infrastructure',
            name: "|gitlab-org|infrastructure_#{time2.to_i}_memory.html",
            created: time2,
            profile_mode: 'Memory'
          },
          {
            request_path: '/gitlab-org/infrastructure',
            name: "|gitlab-org|infrastructure_#{time2.to_i}.html",
            created: time2,
            profile_mode: 'Unknown'
          }
        ]
      end

      before do
        profiles.each do |profile|
          FileUtils.touch(File.join(Gitlab::RequestProfiler::PROFILES_DIR, profile[:name]))
        end
      end

      it 'lists all available profiles' do
        visit admin_requests_profiles_path

        profiles.each do |profile|
          within('.card', text: profile[:request_path]) do
            expect(page).to have_selector(
              "a[href='#{admin_requests_profile_path(profile[:name])}']",
              text: "#{profile[:created].to_s(:long)} #{profile[:profile_mode]}")
          end
        end
      end
    end
  end

  describe 'GET /admin/requests_profiles/:profile' do
    context 'when a profile exists' do
      before do
        File.write("#{Gitlab::RequestProfiler::PROFILES_DIR}/#{profile}", content)
      end

      context 'when is valid call stack profile' do
        let(:content) { 'This is a call stack request profile' }
        let(:profile) { "|gitlab-org|gitlab-ce_#{Time.now.to_i}_execution.html" }

        it 'displays the content' do
          visit admin_requests_profile_path(profile)

          expect(page).to have_content(content)
        end
      end

      context 'when is valid memory profile' do
        let(:content) { 'This is a memory request profile' }
        let(:profile) { "|gitlab-org|gitlab-ce_#{Time.now.to_i}_memory.txt" }

        it 'displays the content' do
          visit admin_requests_profile_path(profile)

          expect(page).to have_content(content)
        end
      end
    end

    context 'when a profile does not exist' do
      it 'shows an error message' do
        visit admin_requests_profile_path('|non|existent_12345.html')

        expect(page).to have_content('Profile not found')
      end
    end
  end
end
