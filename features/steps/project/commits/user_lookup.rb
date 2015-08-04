class Spinach::Features::ProjectCommitsUserLookup < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'I click on commit link' do
    visit namespace_project_commit_path(@project.namespace, @project, sample_commit.id)
  end

  step 'I click on another commit link' do
    visit namespace_project_commit_path(@project.namespace, @project, sample_commit.parent_id)
  end

  step 'I have user with primary email' do
    user_primary
  end

  step 'I have user with secondary email' do
    user_secondary
  end

  step 'I see author based on primary email' do
    check_author_link(sample_commit.author_email, user_primary)
  end

  step 'I see author based on secondary email' do
    check_author_link(sample_commit.author_email, user_secondary)
  end

  def check_author_link(email, user)
    author_link = find('.commit-author-link')
    expect(author_link['href']).to eq user_path(user)
    expect(author_link['data-original-title']).to eq email
    expect(find('.commit-author-name').text).to eq user.name
  end

  def user_primary
    @user_primary ||= create(:user, email: 'dmitriy.zaporozhets@gmail.com')
  end

  def user_secondary
    @user_secondary ||= begin
                          user = create(:user, email: 'dzaporozhets@example.com')
                          create(:email, { user: user, email: 'dmitriy.zaporozhets@gmail.com' })
                          user
                        end
  end
end
