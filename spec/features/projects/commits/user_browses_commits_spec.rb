require 'spec_helper'

describe 'User broweses commits' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  context 'primary email' do
    it 'finds a commit by a primary email' do
      user = create(:user, email: 'dmitriy.zaporozhets@gmail.com')

      visit(project_commit_path(project, RepoHelpers.sample_commit.id))

      check_author_link(RepoHelpers.sample_commit.author_email, user)
    end
  end

  context 'secondary email' do
    it 'finds a commit by a secondary email' do
      user =
        create(:user) do |user|
          create(:email, { user: user, email: 'dmitriy.zaporozhets@gmail.com' })
        end

      visit(project_commit_path(project, RepoHelpers.sample_commit.parent_id))

      check_author_link(RepoHelpers.sample_commit.author_email, user)
    end
  end
end

private

def check_author_link(email, author)
  author_link = find('.commit-author-link')

  expect(author_link['href']).to eq(user_path(author))
  expect(author_link['title']).to eq(email)
  expect(find('.commit-author-name').text).to eq(author.name)
end
