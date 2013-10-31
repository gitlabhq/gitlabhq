require 'spec_helper'

describe ProjectsHelper do
  describe '#project_issues_trackers' do
    it "returns the correct issues trackers available" do
      project_issues_trackers.should ==
          "<option value=\"redmine\">Redmine</option>\n" \
          "<option value=\"gitlab\">GitLab</option>"
    end
  end
end
