require 'spec_helper'

describe Projects::ForkContext do
  describe :fork_by_user do
    before do
      @from_user = create :user
      @from_project = create(:project, creator_id: @from_user.id)
      @to_user = create :user
    end

    context 'fork project' do
      before do
        @to_project = fork_project(@from_project, @to_user)
      end

      it { @to_project.owner.should == @to_user }
      it { @to_project.namespace.should == @to_user.namespace }
    end

    context 'fork project failure' do
      before do
        #corrupt the project so the attempt to fork will fail
        @from_project = create(:project, path: "empty")
        @to_project = fork_project(@from_project, @to_user, false)
      end

      it {@to_project.errors.should_not be_empty}
      it {@to_project.errors[:base].should include("Can't fork project. Please try again later") }

    end
  end

  def fork_project(from_project, user, fork_success = true)
    context = Projects::ForkContext.new(from_project, user)
    shell = mock("gitlab_shell")
    shell.stub(fork_repository: fork_success)
    context.stub(gitlab_shell: shell)
    context.execute
  end

end
