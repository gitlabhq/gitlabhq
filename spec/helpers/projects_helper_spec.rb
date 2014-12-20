require 'spec_helper'

describe ProjectsHelper do
  describe '#project_issues_trackers' do
    it "returns the correct issues trackers available" do
      expect(project_issues_trackers).to eq(
          "<option value=\"redmine\">Redmine</option>\n" \
          "<option value=\"gitlab\">GitLab</option>"
      )
    end

    it "returns the correct issues trackers available with current tracker 'gitlab' selected" do
      expect(project_issues_trackers('gitlab')).to eq(
          "<option value=\"redmine\">Redmine</option>\n" \
          "<option selected=\"selected\" value=\"gitlab\">GitLab</option>"
      )
    end

    it "returns the correct issues trackers available with current tracker 'redmine' selected" do
      expect(project_issues_trackers('redmine')).to eq(
          "<option selected=\"selected\" value=\"redmine\">Redmine</option>\n" \
          "<option value=\"gitlab\">GitLab</option>"
      )
    end
  end
end
