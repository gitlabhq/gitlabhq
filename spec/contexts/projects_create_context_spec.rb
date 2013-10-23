require 'spec_helper'

describe Projects::CreateContext do
  before(:each) { ActiveRecord::Base.observers.enable(:user_observer) }
  after(:each) { ActiveRecord::Base.observers.disable(:user_observer) }

  describe :create_by_user do
    before do
      @user = create :user
      @opts = {
        name: "GitLab",
        namespace: @user.namespace
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
        @group = create :group
        @group.add_owner(@user)

        @opts.merge!(namespace_id: @group.id)
        @project = create_project(@user, @opts)
      end

      it { @project.should be_valid }
      it { @project.owner.should == @group }
      it { @project.namespace.should == @group }
    end

    context 'respect configured public setting' do
      before(:each) do
        @settings = double("settings")
        @settings.stub(:issues) { true }
        @settings.stub(:merge_requests) { true }
        @settings.stub(:wiki) { true }
        @settings.stub(:wall) { true }
        @settings.stub(:snippets) { true }
        stub_const("Settings", Class.new)
        Settings.stub_chain(:gitlab, :default_projects_features).and_return(@settings)
      end

      context 'should be public when setting is public' do
        before do
          @settings.stub(:public) { true }
          @project = create_project(@user, @opts)
        end

        it { @project.public.should be_true }
      end

      context 'should be private when setting is not public' do
        before do
          @settings.stub(:public) { false }
          @project = create_project(@user, @opts)
        end

        it { @project.public.should be_false }
      end
    end
  end

  def create_project(user, opts)
    Projects::CreateContext.new(user, opts).execute
  end
end
