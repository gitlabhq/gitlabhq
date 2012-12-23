require 'spec_helper'

describe ApplicationHelper do
  describe 'current_controller?' do
    before do
      controller.stub!(:controller_name).and_return('foo')
    end

    it "returns true when controller matches argument" do
      current_controller?(:foo).should be_true
    end

    it "returns false when controller does not match argument" do
      current_controller?(:bar).should_not be_true
    end

    it "should take any number of arguments" do
      current_controller?(:baz, :bar).should_not be_true
      current_controller?(:baz, :bar, :foo).should be_true
    end
  end

  describe 'current_action?' do
    before do
      stub!(:action_name).and_return('foo')
    end

    it "returns true when action matches argument" do
      current_action?(:foo).should be_true
    end

    it "returns false when action does not match argument" do
      current_action?(:bar).should_not be_true
    end

    it "should take any number of arguments" do
      current_action?(:baz, :bar).should_not be_true
      current_action?(:baz, :bar, :foo).should be_true
    end
  end

  describe "gravatar_icon" do
    let(:user_email) { 'user@email.com' }

    it "should return a generic avatar path when Gravatar is disabled" do
      Gitlab.config.gravatar.stub(:enabled).and_return(false)
      gravatar_icon(user_email).should == 'no_avatar.png'
    end

    it "should return a generic avatar path when email is blank" do
      gravatar_icon('').should == 'no_avatar.png'
    end

    it "should return default gravatar url" do
      stub!(:request).and_return(double(:ssl? => false))
      gravatar_icon(user_email).should match('http://www.gravatar.com/avatar/b58c6f14d292556214bd64909bcdb118')
    end

    it "should use SSL when appropriate" do
      stub!(:request).and_return(double(:ssl? => true))
      gravatar_icon(user_email).should match('https://secure.gravatar.com')
    end

    it "should return custom gravatar path when gravatar_url is set" do
      stub!(:request).and_return(double(:ssl? => false))
      Gitlab.config.gravatar.stub(:plain_url).and_return('http://example.local/?s=%{size}&hash=%{hash}')
      gravatar_icon(user_email, 20).should == 'http://example.local/?s=20&hash=b58c6f14d292556214bd64909bcdb118'
    end

    it "should accept a custom size" do
      stub!(:request).and_return(double(:ssl? => false))
      gravatar_icon(user_email, 64).should match(/\?s=64/)
    end

    it "should use default size when size is wrong" do
      stub!(:request).and_return(double(:ssl? => false))
      gravatar_icon(user_email, nil).should match(/\?s=40/)
    end

    it "should be case insensitive" do
      stub!(:request).and_return(double(:ssl? => false))
      gravatar_icon(user_email).should == gravatar_icon(user_email.upcase + " ")
    end

  end
end
