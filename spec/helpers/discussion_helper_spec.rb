require 'spec_helper'

describe DiscussionHelper do
  let(:project) { FactoryGirl.build(:project) }

  describe "#part_of_discussion" do
    let(:note_on_merge_request_line) { FactoryGirl.build(:note_on_merge_request_line, project: project) }
    let(:note_on_merge_request)      { FactoryGirl.build(:note_on_merge_request, project: project) }
    let(:note_on_commit_line)        { FactoryGirl.build(:note_on_commit_line, project: project) }
    let(:note_on_commit)             { FactoryGirl.build(:note_on_commit, project: project) }

    it "should consider a note on a line in a merge request to be a discussion" do
      part_of_discussion?(note_on_merge_request_line).should be_true
    end

    it "should consider a note on a line in a commit to be a discussion" do
      part_of_discussion?(note_on_commit_line).should be_true
    end

    it "should consider a note in a commit to be a discussion" do
      part_of_discussion?(note_on_commit).should be_true
    end

    it "should not consider a note on a merge request to be a discussion" do
      part_of_discussion?(note_on_merge_request).should be_false
    end
  end

  describe "#discussion_notes" do
    shared_examples "compare attributes" do
      before :each do
        @notes = [note_a]
      end

      let(:note_a) { FactoryGirl.build(:note_on_merge_request_line, { project: project }.merge(note_spec_a)) }
      let(:note_b) { FactoryGirl.build(:note_on_merge_request_line, { project: project }.merge(note_spec_b)) }

      it "should find notes with the same attributes" do
        discussion_notes(note_a).size.should == 1
      end

      it "should not find notes with different attributes" do
        discussion_notes(note_b).size.should == 0
      end
    end

    context "using different line_code attribute" do
      let(:note_spec_a) { { line_code: "0_1_1" } }
      let(:note_spec_b) { { line_code: "0_2_2" } }

      include_examples "compare attributes"
    end

    context "notes with different noteable_id" do
      let(:note_spec_a) { { noteable_id: 1 } }
      let(:note_spec_b) { { noteable_id: 2 } }

      include_examples "compare attributes"
    end

    context "notes with different noteable_type" do
      let(:note_spec_a) { { noteable_type: "MergeRequest" } }
      let(:note_spec_b) { { noteable_type: "Commit" } }

      include_examples "compare attributes"
    end
  end

  describe "rendering" do
    before :each do
      @notes = []
      3.times do
        @notes << FactoryGirl.build(:note_on_merge_request_line, project: project, line_code: "0_1_1")
      end
    end

    let(:note) { FactoryGirl.build(:note_on_merge_request_line, project: project, line_code: "0_1_1") }

    context "when a note is not rendered yet" do
      it "should allow rendering of the discussion" do
        has_rendered?(note).should be_false
      end
    end

    context "once a note has been rendered" do
      before :each do
        discussion_rendered!(note)
      end

      it "should not be rendered anymore" do
        has_rendered?(note).should be_true
      end

      it "should not render any note in the discussion too" do
        @notes.each do |other_note|
          has_rendered?(other_note).should be_true
        end
      end
    end
  end
end
