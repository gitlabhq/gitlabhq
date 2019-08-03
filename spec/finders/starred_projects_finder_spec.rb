# frozen_string_literal: true

require 'spec_helper'

describe StarredProjectsFinder do
  let(:project1) { create(:project, :public, :empty_repo) }
  let(:project2) { create(:project, :public, :empty_repo) }
  let(:other_project) { create(:project, :public, :empty_repo) }

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    user.toggle_star(project1)
    user.toggle_star(project2)
  end

  describe '#execute' do
    let(:finder) { described_class.new(user, params: {}, current_user: current_user) }

    subject { finder.execute }

    describe 'as same user' do
      let(:current_user) { user }

      it { is_expected.to contain_exactly(project1, project2) }
    end

    describe 'as other user' do
      let(:current_user) { other_user }

      it { is_expected.to contain_exactly(project1, project2) }
    end

    describe 'as no user' do
      let(:current_user) { nil }

      it { is_expected.to contain_exactly(project1, project2) }
    end
  end
end
