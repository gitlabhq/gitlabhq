require "spec_helper"

describe MergeRequestsHelper do
  let(:project) { create :project }
  let(:merge_request) { MergeRequest.new }
  let(:ci_service) { CiService.new }
  let(:last_commit) { Commit.new({}) }

  before do
    merge_request.stub(:source_project) { project }
    merge_request.stub(:last_commit) { last_commit }
    project.stub(:ci_service) { ci_service }
    last_commit.stub(:sha) { '12d65c' }
  end

  describe :ci_build_details_path do
    it 'does not include api credentials in a link' do
      ci_service.stub(:build_page) { "http://secretuser:secretpass@jenkins.example.com:8888/job/test1/scm/bySHA1/12d65c" }
      expect(ci_build_details_path(merge_request)).to_not match("secret")
    end
  end
end