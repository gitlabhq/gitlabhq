require 'spec_helper'

describe CreateCommitService do
  let(:service) { CreateCommitService.new }
  let(:project) { FactoryGirl.create(:project) }
  
  describe :execute do
    context 'valid params' do
      let(:commit) do 
        service.execute(project,
          ref: 'refs/heads/master',
          before: '00000000',
          after: '31das312',
          ci_yaml_file: gitlab_ci_yaml,
          commits: [ { message: "Message" } ]
        )
      end

      it { commit.should be_kind_of(Commit) }
      it { commit.should be_valid }
      it { commit.should be_persisted }
      it { commit.should == project.commits.last }
      it { commit.builds.first.should be_kind_of(Build) }
    end

    context "skip tag if there is no build for it" do
      it "creates commit if there is appropriate job" do
        result = service.execute(project,
          ref: 'refs/tags/0_1',
          before: '00000000',
          after: '31das312',
          ci_yaml_file: gitlab_ci_yaml,
          commits: [ { message: "Message" } ]
        )
        result.should be_persisted
      end

      it "creates commit if there is no appropriate job but deploy job has right ref setting" do
        config = YAML.dump({deploy: {deploy: "ls", only: ["0_1"]}})

        result = service.execute(project,
          ref: 'refs/heads/0_1',
          before: '00000000',
          after: '31das312',
          ci_yaml_file: config,
          commits: [ { message: "Message" } ]
        )
        result.should be_persisted
      end
    end

    describe :ci_skip? do
      it "skips builds creation if there is [ci skip] tag in commit message" do
        commits = [{message: "some message[ci skip]"}]
        commit = service.execute(project,
          ref: 'refs/tags/0_1',
          before: '00000000',
          after: '31das312',
          commits: commits,
          ci_yaml_file: gitlab_ci_yaml
        )
        commit.builds.any?.should be_false
        commit.status.should == "skipped"
      end

      it "does not skips builds creation if there is no [ci skip] tag in commit message" do
        commits = [{message: "some message"}]

        commit = service.execute(project,
          ref: 'refs/tags/0_1',
          before: '00000000',
          after: '31das312',
          commits: commits,
          ci_yaml_file: gitlab_ci_yaml
        )
        
        commit.builds.first.name.should == "staging"
      end

      it "skips builds creation if there is [ci skip] tag in commit message and yaml is invalid" do
        commits = [{message: "some message[ci skip]"}]
        commit = service.execute(project,
                                 ref: 'refs/tags/0_1',
                                 before: '00000000',
                                 after: '31das312',
                                 commits: commits,
                                 ci_yaml_file: "invalid: file"
        )
        commit.builds.any?.should be_false
        commit.status.should == "skipped"
      end
    end

    it "skips build creation if there are already builds" do
      commits = [{message: "message"}]
      commit = service.execute(project,
        ref: 'refs/heads/master',
        before: '00000000',
        after: '31das312',
        commits: commits,
        ci_yaml_file: gitlab_ci_yaml
      )
      commit.builds.count(:all).should == 2

      commit = service.execute(project,
        ref: 'refs/heads/master',
        before: '00000000',
        after: '31das312',
        commits: commits,
        ci_yaml_file: gitlab_ci_yaml
      )
      commit.builds.count(:all).should == 2
    end

    it "creates commit with failed status if yaml is invalid" do
      commits = [{message: "some message"}]

      commit = service.execute(project,
                               ref: 'refs/tags/0_1',
                               before: '00000000',
                               after: '31das312',
                               commits: commits,
                               ci_yaml_file: "invalid: file"
      )

      commit.status.should == "failed"
      commit.builds.any?.should be_false
    end
  end
end
