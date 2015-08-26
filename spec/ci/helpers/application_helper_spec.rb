require 'spec_helper'

describe ApplicationHelper do
  describe "#duration_in_words" do
    it "returns minutes and seconds" do
      intervals_in_words = {
        100 => "1 minute 40 seconds",
        121 => "2 minutes 1 second",
        3721 => "62 minutes 1 second",
        0 => "0 seconds"
      }

      intervals_in_words.each do |interval, expectation|
        duration_in_words(Time.now + interval, Time.now).should == expectation
      end
    end

    it "calculates interval from now if there is no finished_at" do
      duration_in_words(nil, Time.now - 5).should == "5 seconds"
    end
  end

  describe "#time_interval_in_words" do
    it "returns minutes and seconds" do
      intervals_in_words = {
        100 => "1 minute 40 seconds",
        121 => "2 minutes 1 second",
        3721 => "62 minutes 1 second",
        0 => "0 seconds"
      }

      intervals_in_words.each do |interval, expectation|
        time_interval_in_words(interval).should == expectation
      end
    end
  end
end
