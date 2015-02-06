class Spinach::Features::ProjectGroupLinks < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include Select2Helper

  step 'I should see project already shared with group "Ops"' do
    within '.enabled-groups' do
      page.should have_content "Ops"
    end
  end

  step 'I should see project is not shared with group "Market"' do
    within '.enabled-groups' do
      page.should_not have_content "Market"
    end
  end

  step 'I select group "Market" for share' do
    group = Group.find_by(path: 'market')
    select2(group.id, from: "#link_group_id")
    select "Master", from: 'link_group_access'
    click_button "Share"
  end

  step 'I should see project is shared with group "Market"' do
    within '.enabled-groups' do
      page.should have_content "Market"
    end
  end

  step 'project "Shop" is shared with group "Ops"' do
    group = create(:group, name: 'Ops')
    share_link = project.project_group_links.new(group_access: Gitlab::Access::MASTER)
    share_link.group_id = group.id
    share_link.save!
  end

  step 'project "Shop" is not shared with group "Market"' do
    create(:group, name: 'Market', path: 'market')
  end

  step 'I visit project group links page' do
    visit project_group_links_path(project)
  end

  def project
    @project ||= Project.find_by_name "Shop"
  end
end
