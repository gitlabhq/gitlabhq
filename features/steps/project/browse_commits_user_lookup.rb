class ProjectBrowseCommitsUserLookup < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  Given 'I click on commit link' do
    visit project_commit_path(@project, sample_commit.id)
  end

  Given 'I click on another commit link' do
    visit project_commit_path(@project, sample_commit.parent_id)
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
    author_link['href'].should == user_path(user)
    author_link['data-original-title'].should == email
    find('.commit-author-name').text.should == user.name
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
