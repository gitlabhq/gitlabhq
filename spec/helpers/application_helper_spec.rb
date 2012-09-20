require 'spec_helper'

describe ApplicationHelper do
  describe 'layout_type' do
    it "returns :project when @project is present" do
      @project = create(:project)
      layout_type.should == :project
    end

    it "returns :admin when on an AdminController" do
      controller.stub!(:kind_of?).with(AdminController).and_return(true)
      layout_type.should == :admin
    end

    it "returns :profile when on DashboardController" do
      controller.stub!(:class).and_return(DashboardController)
      layout_type.should == :profile
    end

    it "returns :profile when on ProfileController" do
      controller.stub!(:class).and_return(ProfileController)
      layout_type.should == :profile
    end

    it "returns :application otherwise" do
      layout_type.should == :application
    end
  end

  describe 'header_title' do
    it "returns project name on project" do
      @project = create(:project)
      stub!(:layout_type).and_return(:project)
      header_title.should == @project.name
    end

    it "returns Admin Area on admin" do
      stub!(:layout_type).and_return(:admin)
      header_title.should == 'Admin Area'
    end

    it "returns Dashboard on dashboard" do
      stub!(:layout_type).and_return(:profile)
      controller.stub!(:class).and_return(DashboardController)
      header_title.should == 'Dashboard'
    end

    it "returns Profile on profile" do
      stub!(:layout_type).and_return(:profile)
      controller.stub!(:class).and_return(ProfileController)
      header_title.should == 'Profile'
    end

    it "returns GitLab otherwise" do
      header_title.should == 'GitLab'
    end
  end

  describe "gravatar_icon" do
    let(:user_email) { 'user@email.com' }

    it "should return a generic avatar path when Gravatar is disabled" do
      Gitlab.config.stub(:disable_gravatar?).and_return(true)
      gravatar_icon(user_email).should == 'no_avatar.png'
    end

    it "should return a generic avatar path when email is blank" do
      gravatar_icon('').should == 'no_avatar.png'
    end

    it "should use SSL when appropriate" do
      stub!(:request).and_return(double(:ssl? => true))
      gravatar_icon(user_email).should match('https://secure.gravatar.com')
    end

    it "should accept a custom size" do
      stub!(:request).and_return(double(:ssl? => false))
      gravatar_icon(user_email, 64).should match(/\?s=64/)
    end
  end
end
