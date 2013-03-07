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
  end

  def fork_project(from_project, user)
    Projects::ForkContext.new(from_project, user).execute
  end
end
