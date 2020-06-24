# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComponentsHelper do
  describe '#gitlab_workhorse_version' do
    context 'without a Gitlab-Workhorse header' do
      it 'shows the version from Gitlab::Workhorse.version' do
        expect(helper.gitlab_workhorse_version).to eq Gitlab::Workhorse.version
      end
    end

    context 'with a Gitlab-Workhorse header' do
      before do
        helper.request.headers['Gitlab-Workhorse'] = '42.42.0-rc3'
      end

      it 'shows the actual GitLab Workhorse version currently in use' do
        expect(helper.gitlab_workhorse_version).to eq '42.42.0'
      end
    end
  end
end
