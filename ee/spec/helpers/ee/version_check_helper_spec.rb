# frozen_string_literal: true

require 'spec_helper'

describe EE::VersionCheckHelper do
  include StubVersion

  describe '#link_to_version' do
    context 'for a pre-release' do
      before do
        stub_version('8.0.2-pre', 'deadbeef')
      end

      it 'links to an ee-commit' do
        expect(helper.link_to_version).to include('https://gitlab.com/gitlab-org/gitlab-ee/commits/deadbeef')
      end
    end

    context 'for a normal release' do
      before do
        stub_version('8.0.2-ee', 'deadbeef')
      end

      it 'links to an ee-tag' do
        expect(helper.link_to_version).to include('https://gitlab.com/gitlab-org/gitlab-ee/tags/v8.0.2-ee')
      end
    end
  end
end
