require 'spec_helper'

feature 'Merge request environments', :feature, :js do
  include WaitForAjax

  it 'shows environments link' do
    project = create(:project)
    merge_request = create(:merge_request, source_project: project)
    environment = create(:environment, project: project)
    create(:deployment, environment: environment, ref: 'feature', sha: merge_request.diff_head_sha)

    login_as :admin

    visit namespace_project_merge_request_path(project.namespace, project, merge_request)

    wait_for_ajax

    page.within('.mr-widget-heading') do
      expect(page).to have_content("Deployed to #{environment.name}")
      expect(find('.js-environment-link')[:href]).to include(environment.formatted_external_url)
    end
  end
end
