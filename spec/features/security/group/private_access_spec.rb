require 'rails_helper'

describe 'Private Group access', feature: true do
  include AccessMatchers

  let(:group) { create(:group, :private) }
  let(:project) { create(:project, :private, group: group) }

  let(:owner)     { create(:user) }
  let(:master)    { create(:user) }
  let(:developer) { create(:user) }
  let(:reporter)  { create(:user) }
  let(:guest)     { create(:user) }

  let(:project_guest) { create(:user) }

  before do
    group.add_owner(owner)
    group.add_master(master)
    group.add_developer(developer)
    group.add_reporter(reporter)
    group.add_guest(guest)

    project.team << [project_guest, :guest]
  end

  describe "Group should be private" do
    describe '#private?' do
      subject { group.private? }
      it { is_expected.to be_truthy }
    end
  end

  describe 'GET /groups/:path' do
    subject { group_path(group) }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for owner }
    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_allowed_for developer }
    it { is_expected.to be_allowed_for reporter }
    it { is_expected.to be_allowed_for guest }
    it { is_expected.to be_allowed_for project_guest }
    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :external }
    it { is_expected.to be_denied_for :visitor }
  end

  describe 'GET /groups/:path/issues' do
    subject { issues_group_path(group) }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for owner }
    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_allowed_for developer }
    it { is_expected.to be_allowed_for reporter }
    it { is_expected.to be_allowed_for guest }
    it { is_expected.to be_allowed_for project_guest }
    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :external }
    it { is_expected.to be_denied_for :visitor }
  end

  describe 'GET /groups/:path/merge_requests' do
    subject { merge_requests_group_path(group) }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for owner }
    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_allowed_for developer }
    it { is_expected.to be_allowed_for reporter }
    it { is_expected.to be_allowed_for guest }
    it { is_expected.to be_allowed_for project_guest }
    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :external }
    it { is_expected.to be_denied_for :visitor }
  end

  describe 'GET /groups/:path/group_members' do
    subject { group_group_members_path(group) }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for owner }
    it { is_expected.to be_allowed_for master }
    it { is_expected.to be_allowed_for developer }
    it { is_expected.to be_allowed_for reporter }
    it { is_expected.to be_allowed_for guest }
    it { is_expected.to be_allowed_for project_guest }
    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :external }
    it { is_expected.to be_denied_for :visitor }
  end

  describe 'GET /groups/:path/edit' do
    subject { edit_group_path(group) }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for owner }
    it { is_expected.to be_denied_for master }
    it { is_expected.to be_denied_for developer }
    it { is_expected.to be_denied_for reporter }
    it { is_expected.to be_denied_for guest }
    it { is_expected.to be_denied_for project_guest }
    it { is_expected.to be_denied_for :user }
    it { is_expected.to be_denied_for :visitor }
    it { is_expected.to be_denied_for :external }
  end
end
