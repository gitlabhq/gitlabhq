require 'spec_helper'

describe NotesHelper do
  describe "#emoji_for_completion" do
    it "should be an Array of Strings" do
      emoji_for_completion.should be_a(Array)
      emoji_for_completion.each { |emoji| emoji.should be_a(String) }
    end
  end
end
