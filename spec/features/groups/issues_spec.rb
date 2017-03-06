require 'spec_helper'

feature 'Group issues page', feature: true do
  let(:path) { issues_group_path(group) }
  let(:issuable) { create(:issue, project: project, title: "this is my created issuable")}

  include_examples 'project features apply to issuables', Issue

  context 'rss feed' do
    let(:access_level) { ProjectFeature::ENABLED }

    context 'when signed in' do
      let(:user) { user_in_group }

      it_behaves_like "it has an RSS button with current_user's private token"
      it_behaves_like "an autodiscoverable RSS feed with current_user's private token"
    end

    context 'when signed out' do
      let(:user) { nil }

      it_behaves_like "it has an RSS button without a private token"
      it_behaves_like "an autodiscoverable RSS feed without a private token"
    end
  end
end
