require 'spec_helper'

describe ProjectsHelper do
  describe "#project_status_css_class" do
    it "returns appropriate class" do
      expect(project_status_css_class("started")).to eq("active")
      expect(project_status_css_class("failed")).to eq("danger")
      expect(project_status_css_class("finished")).to eq("success")
    end
  end
end
