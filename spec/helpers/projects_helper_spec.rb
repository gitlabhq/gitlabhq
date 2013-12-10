require 'spec_helper'

describe ProjectsHelper do
  describe '#project_issues_trackers' do
    it "returns the correct issues trackers available" do
      project_issues_trackers.should ==
          "<option value=\"redmine\">Redmine</option>\n" \
          "<option value=\"gitlab\">GitLab</option>"
    end

    it "returns the correct issues trackers available with current tracker 'gitlab' selected" do
      project_issues_trackers('gitlab').should ==
          "<option value=\"redmine\">Redmine</option>\n" \
          "<option selected=\"selected\" value=\"gitlab\">GitLab</option>"
    end

    it "returns the correct issues trackers available with current tracker 'redmine' selected" do
      project_issues_trackers('redmine').should ==
          "<option selected=\"selected\" value=\"redmine\">Redmine</option>\n" \
          "<option value=\"gitlab\">GitLab</option>"
    end
  end
end
