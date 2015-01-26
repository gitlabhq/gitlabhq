require 'spec_helper'

describe ProjectsHelper do
  describe "#project_status_css_class" do
    it "returns appropriate class" do
      project_status_css_class("started").should == "active"
      project_status_css_class("failed").should == "danger"
      project_status_css_class("finished").should == "success"
    end
  end
end
