class ProjectBrowseCommitsUserLookup < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  
  Given 'I have the user that authored the commits' do
    @user = create(:user, email: 'dmitriy.zaporozhets@gmail.com')
    create(:email, { user: @user, email: 'dzaporozhets@sphereconsultinginc.com' })
  end

  Given 'I click on commit link' do
    visit project_commit_path(@project, ValidCommit::ID)
  end

  Given 'I click on another commit link' do
    visit project_commit_path(@project, ValidCommitWithAltEmail::ID)
  end

  Then 'I see commit info' do
    page.should have_content ValidCommit::MESSAGE
    check_author_link(ValidCommit::AUTHOR_EMAIL)
  end
  
  Then 'I see other commit info' do
    page.should have_content ValidCommitWithAltEmail::MESSAGE
    check_author_link(ValidCommitWithAltEmail::AUTHOR_EMAIL)
  end

  def check_author_link(email)
    author_link = find('.commit-author-link')
    author_link['href'].should == user_path(@user)
    author_link['data-original-title'].should == email
    find('.commit-author-name').text.should == @user.name
  end
end
