require 'rails_helper'

describe PipelinesHelper do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project, sha: project.commit.id, user: user) }

  describe '#pipeline_user_avatar' do
    subject { helper.pipeline_user_avatar(pipeline) }

    it "links to the user's profile" do
      is_expected.to include("href=\"#{user_path(user)}\"")
    end

    it "has the user's name as title" do
      is_expected.to include("title=\"#{user.name}\"")
    end

    it "contains the user's avatar image" do
      is_expected.to include(CGI.escapeHTML(user.avatar_url(24)))
    end
  end

  describe '#pipeline_user_link' do
    subject { helper.pipeline_user_link(pipeline) }

    it "links to the user's profile" do
      is_expected.to include("href=\"#{user_path(user)}\"")
    end

    it "has the user's email as title" do
      is_expected.to include("title=\"#{user.email}\"")
    end
  end
end
