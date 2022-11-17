# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersStarProjectsFinder do
  let(:project) { create(:project, :public, :empty_repo) }

  let(:user) { create(:user) }
  let(:private_user) { create(:user, private_profile: true) }
  let(:other_user) { create(:user) }
  let(:blocked_user) { create(:user, state: 'blocked') }

  before do
    user.toggle_star(project)
    private_user.toggle_star(project)
    blocked_user.toggle_star(project)
  end

  describe '#execute' do
    let(:finder) { described_class.new(project, {}, current_user: current_user) }
    let(:public_stars) { user.users_star_projects }
    let(:private_stars) { private_user.users_star_projects }

    subject { finder.execute }

    describe 'as same user' do
      let(:current_user) { private_user }

      it { is_expected.to match_array(private_stars + public_stars) }
    end

    describe 'as other user' do
      let(:current_user) { other_user }

      it { is_expected.to match_array(public_stars) }
    end

    describe 'as no user' do
      let(:current_user) { nil }

      it { is_expected.to match_array(public_stars) }
    end

    describe 'with active users only' do
      let(:current_user) { private_user }

      it 'ignores stars of non-active users' do
        is_expected.not_to include(*blocked_user.users_star_projects)
      end
    end
  end
end
