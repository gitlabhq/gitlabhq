require 'spec_helper'

describe 'User browses commits' do
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

  context 'when the blob does not exist' do
    let(:commit) { create(:commit, project: project) }

    it 'shows a blank label' do
      allow_any_instance_of(Gitlab::Diff::File).to receive(:blob).and_return(nil)
      allow_any_instance_of(Gitlab::Diff::File).to receive(:raw_binary?).and_return(true)

      visit(project_commit_path(project, commit))

      expect(find('.diff-file-changes', visible: false)).to have_content('No file name available')
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
