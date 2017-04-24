require 'rails_helper'

describe Projects::RelatedIssuesController, type: :controller do
  let(:user) { create :user }
  let(:project) { create(:project_empty_repo) }
  let(:issue) { create :issue, project: project }

  describe "GET #index" do
    let(:issue_b) { create :issue, project: project }
    let(:issue_c) { create :issue, project: project }
    let(:issue_d) { create :issue, project: project }

    let!(:related_issue_a) do
      create(:related_issue, issue: issue,
                             related_issue: issue_b,
                             created_at: 2.days.ago)
    end

    let!(:related_issue_b) do
      create(:related_issue, issue: issue,
                             related_issue: issue_c,
                             created_at: 1.day.ago)
    end

    let!(:related_issue_c) do
      create(:related_issue, issue: issue_d,
                             related_issue: issue,
                             created_at: Date.today)
    end

    it "returns related issues JSON" do
      sign_in user
      project.team << [user, :developer]

      get :index, namespace_id: issue.project.namespace,
                  project_id: issue.project,
                  issue_id: issue,
                  format: :json



      expect(json_response.size).to eq(3)

      expect(json_response[0]).to eq(
        {
          "title" => issue_b.title,
          "state" => issue_b.state,
          "reference" => issue_b.to_reference(project),
          "path" => "/#{project.full_path}/issues/#{issue_b.iid}"
        }
      )

      expect(json_response[1]).to eq(
        {
          "title" => issue_c.title,
          "state" => issue_c.state,
          "reference" => issue_c.to_reference(project),
          "path" => "/#{project.full_path}/issues/#{issue_c.iid}"
        }
      )

      expect(json_response[2]).to eq(
        {
          "title" => issue_d.title,
          "state" => issue_d.state,
          "reference" => issue_d.to_reference(project),
          "path" => "/#{project.full_path}/issues/#{issue_d.iid}"
        }
      )
    end
  end

  xdescribe "GET #create" do
    it "returns http success" do
      get :create
      expect(response).to have_http_status(:success)
    end
  end
end
