# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InvitesHelper, feature_category: :system_access do
  let(:organization) { build_stubbed(:organization) } # non-default org => scoped_paths? == true
  let(:group) { build_stubbed(:group, organization: organization) }
  let(:member) { build_stubbed(:group_member, :invited, source: group) }

  let(:token) { 'ABC123token' }

  def path_of(url)
    URI.parse(url).path
  end

  describe '#invite_url_for' do
    context 'when the organization uses scoped paths' do
      it 'returns an organization-scoped invite URL' do
        expect(path_of(helper.invite_url_for(member, token)))
          .to eq("/o/#{organization.path}/-/invites/#{token}")
      end
    end

    context 'when the organization serves unscoped (default) paths' do
      before do
        allow(organization).to receive(:scoped_paths?).and_return(false)
      end

      it 'returns the unscoped invite URL' do
        expect(path_of(helper.invite_url_for(member, token))).to eq("/-/invites/#{token}")
      end
    end

    context 'when the member has no source' do
      before do
        allow(member).to receive(:source).and_return(nil)
      end

      it 'returns the unscoped invite URL' do
        expect(path_of(helper.invite_url_for(member, token))).to eq("/-/invites/#{token}")
      end
    end

    context 'when the source has no organization' do
      before do
        allow(group).to receive(:organization).and_return(nil)
      end

      it 'returns the unscoped invite URL' do
        expect(path_of(helper.invite_url_for(member, token))).to eq("/-/invites/#{token}")
      end
    end
  end

  describe '#accept_invite_url_for' do
    it 'returns an organization-scoped accept URL' do
      expect(path_of(helper.accept_invite_url_for(member, token)))
        .to eq("/o/#{organization.path}/-/invites/#{token}/accept")
    end
  end

  describe '#decline_invite_url_for' do
    it 'returns an organization-scoped decline URL' do
      expect(path_of(helper.decline_invite_url_for(member, token)))
        .to eq("/o/#{organization.path}/-/invites/#{token}/decline")
    end
  end
end
