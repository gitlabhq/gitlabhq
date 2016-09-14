require 'spec_helper'

describe SearchHelper do
  # Override simple_sanitize for our testing purposes
  def simple_sanitize(str)
    str
  end

  describe 'parsing result' do
    let(:project) { create(:project) }
    let(:repository) { project.repository }
    let(:results) { repository.search_files('feature', 'master') }
    let(:search_result) { results.first }

    subject { helper.parse_search_result(search_result) }

    it "returns a valid OpenStruct object" do
      is_expected.to be_an OpenStruct
      expect(subject.filename).to eq('CHANGELOG')
      expect(subject.basename).to eq('CHANGELOG')
      expect(subject.ref).to eq('master')
      expect(subject.startline).to eq(186)
      expect(subject.data.lines[2]).to eq("  - Feature: Replace teams with group membership\n")
    end

    context "when filename has extension" do
      let(:search_result) { "master:CONTRIBUTE.md:5:- [Contribute to GitLab](#contribute-to-gitlab)\n" }

      it { expect(subject.filename).to eq('CONTRIBUTE.md') }
      it { expect(subject.basename).to eq('CONTRIBUTE') }
    end

    context "when file under directory" do
      let(:search_result) { "master:a/b/c.md:5:a b c\n" }

      it { expect(subject.filename).to eq('a/b/c.md') }
      it { expect(subject.basename).to eq('a/b/c') }
    end
  end

  describe 'search_autocomplete_source' do
    context "with no current user" do
      before do
        allow(self).to receive(:current_user).and_return(nil)
      end

      it "it returns nil" do
        expect(search_autocomplete_opts("q")).to be_nil
      end
    end

    context "with a user" do
      let(:user)   { create(:user) }

      before do
        allow(self).to receive(:current_user).and_return(user)
      end

      it "includes Help sections" do
        expect(search_autocomplete_opts("hel").size).to eq(9)
      end

      it "includes default sections" do
        expect(search_autocomplete_opts("adm").size).to eq(1)
      end

      it "does not allow regular expression in search term" do
        expect(search_autocomplete_opts("(webhooks|api)").size).to eq(0)
      end

      it "includes the user's groups" do
        create(:group).add_owner(user)
        expect(search_autocomplete_opts("gro").size).to eq(1)
      end

      it "includes the user's projects" do
        project = create(:project, namespace: create(:namespace, owner: user))
        expect(search_autocomplete_opts(project.name).size).to eq(1)
      end

      it "does not include the public group" do
        group = create(:group)
        expect(search_autocomplete_opts(group.name).size).to eq(0)
      end

      context "with a current project" do
        before { @project = create(:project) }

        it "includes project-specific sections" do
          expect(search_autocomplete_opts("Files").size).to eq(1)
          expect(search_autocomplete_opts("Commits").size).to eq(1)
        end
      end
    end
  end
end
