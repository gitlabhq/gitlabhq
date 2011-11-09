require 'spec_helper'

describe ApplicationHelper do
  context ".gravatar_icon" do
    context "over http" do
      it "returns the correct URL to www.gravatar.com" do
        expected = "http://www.gravatar.com/avatar/f7daa65b2aa96290bb47c4d68d11fe6a?s=40&d=identicon"

        # Pretend we're running over HTTP
        helper.stub(:request) do
          request = double('request')
          request.stub(:ssl?) { false }
          request
        end

        helper.gravatar_icon("admin@local.host").should == expected
      end
    end

    context "over https" do
      it "returns the correct URL to secure.gravatar.com" do
        expected = "https://secure.gravatar.com/avatar/f7daa65b2aa96290bb47c4d68d11fe6a?s=40&d=identicon"

        # Pretend we're running over HTTPS
        helper.stub(:request) do
          request = double('request')
          request.stub(:ssl?) { true }
          request
        end

        helper.gravatar_icon("admin@local.host").should == expected
      end
    end
  end
end
