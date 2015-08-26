require 'spec_helper'

describe RunnersHelper do
  it "returns - not contacted yet" do
    runner = FactoryGirl.build :runner
    runner_status_icon(runner).should include("not connected yet")
  end

  it "returns offline text" do
    runner = FactoryGirl.build(:runner, contacted_at: 1.day.ago, active: true)
    runner_status_icon(runner).should include("Runner is offline")
  end

  it "returns online text" do
    runner = FactoryGirl.build(:runner, contacted_at: 1.hour.ago, active: true)
    runner_status_icon(runner).should include("Runner is online")
  end
end
