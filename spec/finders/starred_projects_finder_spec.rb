# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StarredProjectsFinder do
  let(:project1) { create(:project, :public, :empty_repo) }
  let(:project2) { create(:project, :public, :empty_repo) }
  let(:private_project) { create(:project, :private, :empty_repo) }

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    user.toggle_star(project1)
    user.toggle_star(project2)

    private_project.add_maintainer(user)
    user.toggle_star(private_project)
  end

  describe '#execute' do
    let(:finder) { described_class.new(user, params: {}, current_user: current_user) }

    subject { finder.execute }

    context 'user has a public profile' do
      describe 'as same user' do
        let(:current_user) { user }

        it { is_expected.to contain_exactly(project1, project2, private_project) }
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

    context 'user has a private profile' do
      before do
        user.update!(private_profile: true)
      end

      describe 'as same user' do
        let(:current_user) { user }

        it { is_expected.to contain_exactly(project1, project2, private_project) }
      end

      describe 'as other user' do
        context 'user does not have access to view the private profile' do
          let(:current_user) { other_user }

          it { is_expected.to be_empty }
        end

        context 'user has access to view the private profile', :enable_admin_mode do
          let(:current_user) { create(:admin) }

          it { is_expected.to contain_exactly(project1, project2, private_project) }
        end
      end

      describe 'as no user' do
        let(:current_user) { nil }

        it { is_expected.to be_empty }
      end
    end
  end
end
