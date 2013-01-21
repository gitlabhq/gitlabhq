require 'spec_helper'

describe Projects::CreateContext do
  describe :create_by_user do
    before do
      @user = create :user
      @opts = {
        name: "GitLab"
      }
    end

    context 'user namespace' do
      before do
        @project = create_project(@user, @opts)
      end

      it { @project.should be_valid }
      it { @project.owner.should == @user }
      it { @project.namespace.should == @user.namespace }
    end

    context 'group namespace' do
      before do
        @group = create :group, owner: @user
        @opts.merge!(namespace_id: @group.id)
        @project = create_project(@user, @opts)
      end

      it { @project.should be_valid }
      it { @project.owner.should == @user }
      it { @project.namespace.should == @group }
    end
  end

  def create_project(user, opts)
    Projects::CreateContext.new(user, opts).execute
  end
end
