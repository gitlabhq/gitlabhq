require 'spec_helper'

feature 'Group issues page', feature: true do
  let(:path) { issues_group_path(group) }
  let(:issuable) { create(:issue, project: project, title: "this is my created issuable")}

  include_examples 'project features apply to issuables', Issue
end
