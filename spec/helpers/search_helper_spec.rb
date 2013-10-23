require 'spec_helper'

describe SearchHelper do
  # Override simple_sanitize for our testing purposes
  def simple_sanitize(str)
    str
  end

  describe 'search_autocomplete_source' do
    context "with no current user" do
      before { stub!(:current_user).and_return(nil) }

      it "it returns nil" do
        search_autocomplete_source.should be_nil
      end
    end

    context "with a user" do
      let(:user)   { create(:user) }
      let(:result) { JSON.parse(search_autocomplete_source) }

      before do
        stub!(:current_user).and_return(user)
      end

      it "includes Help sections" do
        result.select { |h| h['label'] =~ /^help:/ }.length.should == 9
      end

      it "includes default sections" do
        result.count { |h| h['label'] =~ /^(My|Admin)\s/ }.should == 4
      end

      it "includes the user's groups" do
        create(:group).add_owner(user)
        result.count { |h| h['label'] =~ /^group:/ }.should == 1
      end

      it "includes the user's projects" do
        create(:project, namespace: create(:namespace, owner: user))
        result.count { |h| h['label'] =~ /^project:/ }.should == 1
      end

      context "with a current project" do
        before { @project = create(:project_with_code) }

        it "includes project-specific sections" do
          result.count { |h| h['label'] =~ /^#{@project.name_with_namespace} - / }.should == 11
        end

        it "uses @ref in urls if defined" do
          @ref = "foo_bar"
          result.count { |h| h['url'] == project_tree_path(@project, @ref) }.should == 1
        end
      end

      context "with no current project" do
        it "does not include project-specific sections" do
          result.count { |h| h['label'] =~ /Files$/ }.should == 0
        end
      end
    end
  end
end
