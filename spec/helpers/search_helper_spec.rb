require 'spec_helper'

describe SearchHelper do
  # Override simple_sanitize for our testing purposes
  def simple_sanitize(str)
    str
  end

  describe 'search_autocomplete_source' do
    context "with no current user" do
      before do
        allow(self).to receive(:current_user).and_return(nil)
      end

      it "it returns nil" do
        search_autocomplete_opts("q").should be_nil
      end
    end

    context "with a user" do
      let(:user)   { create(:user) }

      before do
        allow(self).to receive(:current_user).and_return(user)
      end

      it "includes Help sections" do
        search_autocomplete_opts("hel").size.should == 9
      end

      it "includes default sections" do
        search_autocomplete_opts("adm").size.should == 1
      end

      it "includes the user's groups" do
        create(:group).add_owner(user)
        search_autocomplete_opts("gro").size.should == 1
      end

      it "includes the user's projects" do
        project = create(:project, namespace: create(:namespace, owner: user))
        search_autocomplete_opts(project.name).size.should == 1
      end

      context "with a current project" do
        before { @project = create(:project) }

        it "includes project-specific sections" do
          search_autocomplete_opts("Files").size.should == 1
          search_autocomplete_opts("Commits").size.should == 1
        end
      end
    end
  end
end
