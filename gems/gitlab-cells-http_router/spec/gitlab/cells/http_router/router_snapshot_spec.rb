# frozen_string_literal: true

RSpec.describe Gitlab::Cells::HttpRouter::RouterSnapshot do
  describe ".url" do
    it "points at the router snapshot via the Repository Files API on the default ref" do
      expect(described_class.url).to eq(
        "https://gitlab.com/api/v4/projects/gitlab-org%2Fcells%2Fhttp-router" \
          "/repository/files/test%2Froutes%2Fgitlab_routes.json/raw?ref=main"
      )
    end

    it "accepts another ref" do
      expect(described_class.url(ref: "my-branch")).to eq(
        "https://gitlab.com/api/v4/projects/gitlab-org%2Fcells%2Fhttp-router" \
          "/repository/files/test%2Froutes%2Fgitlab_routes.json/raw?ref=my-branch"
      )
    end

    it "accepts another project, so a fork can be compared against" do
      expect(described_class.url(project: "my-fork/http-router")).to eq(
        "https://gitlab.com/api/v4/projects/my-fork%2Fhttp-router" \
          "/repository/files/test%2Froutes%2Fgitlab_routes.json/raw?ref=main"
      )
    end

    it "accepts a custom API URL, for self-managed instances" do
      expect(described_class.url(api_url: "https://example.com/api/v4")).to eq(
        "https://example.com/api/v4/projects/gitlab-org%2Fcells%2Fhttp-router" \
          "/repository/files/test%2Froutes%2Fgitlab_routes.json/raw?ref=main"
      )
    end
  end

  describe ".url_from_env" do
    it "falls back to the defaults when nothing is set" do
      expect(described_class.url_from_env({})).to eq(described_class.url)
    end

    it "honours a ref override" do
      url = described_class.url_from_env({ "CELLS_ROUTER_REF" => "my-branch" })

      expect(url).to eq(described_class.url(ref: "my-branch"))
    end

    it "honours a project override" do
      url = described_class.url_from_env({ "CELLS_ROUTER_PROJECT" => "my-fork/http-router" })

      expect(url).to eq(described_class.url(project: "my-fork/http-router"))
    end

    it "honours a CI_API_V4_URL override" do
      url = described_class.url_from_env({ "CI_API_V4_URL" => "https://example.com/api/v4" })

      expect(url).to eq(described_class.url(api_url: "https://example.com/api/v4"))
    end

    it "lets a full URL override bypass all other variables" do
      url = described_class.url_from_env(
        {
          "CELLS_ROUTER_SNAPSHOT_URL" => "https://example.com/snapshot.json",
          "CELLS_ROUTER_REF" => "ignored",
          "CI_API_V4_URL" => "ignored"
        }
      )

      expect(url).to eq("https://example.com/snapshot.json")
    end
  end

  describe ".job_token" do
    it "returns nil when CI_JOB_TOKEN is not set" do
      expect(described_class.job_token({})).to be_nil
    end

    it "returns nil when CI_JOB_TOKEN is empty" do
      expect(described_class.job_token({ "CI_JOB_TOKEN" => "" })).to be_nil
    end

    it "returns the token when CI_JOB_TOKEN is set" do
      expect(described_class.job_token({ "CI_JOB_TOKEN" => "glcbt-123" })).to eq("glcbt-123")
    end
  end
end
