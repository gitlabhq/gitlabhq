class Spinach::Features::ProjectIssuesMilestones < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include SharedMarkdown

  step 'project "Shop" has milestone "v2.2"' do
    project = Project.find_by(name: "Shop")
    milestone = create(:milestone,
                       title: "v2.2",
                       project: project,
                       description: "# Description header"
                      )
    3.times { create(:issue, project: project, milestone: milestone) }
  end

  When 'I click link "All Issues"' do
    click_link 'All Issues'
  end
end
