require 'spec_helper'

describe "Factories" do
  describe 'User' do
    it "builds a valid instance" do
      build(:user).should be_valid
    end

    it "builds a valid admin instance" do
      build(:admin).should be_valid
    end
  end

  describe 'Project' do
    it "builds a valid instance" do
      build(:project).should be_valid
    end
  end

  describe 'Issue' do
    it "builds a valid instance" do
      build(:issue).should be_valid
    end

    it "builds a valid closed instance" do
      build(:closed_issue).should be_valid
    end
  end

  describe 'MergeRequest' do
    it "builds a valid instance" do
      build(:merge_request).should be_valid
    end
  end

  describe 'Note' do
    it "builds a valid instance" do
      build(:note).should be_valid
    end
  end

  describe 'Event' do
    it "builds a valid instance" do
      build(:event).should be_valid
    end
  end

  describe 'Key' do
    it "builds a valid instance" do
      build(:key).should be_valid
    end

    it "builds a valid deploy key instance" do
      build(:deploy_key).should be_valid
    end

    it "builds a valid personal key instance" do
      build(:personal_key).should be_valid
    end
  end

  describe 'Milestone' do
    it "builds a valid instance" do
      build(:milestone).should be_valid
    end
  end

  describe 'SystemHook' do
    it "builds a valid instance" do
      build(:system_hook).should be_valid
    end
  end

  describe 'ProjectHook' do
    it "builds a valid instance" do
      build(:project_hook).should be_valid
    end
  end

  describe 'Wiki' do
    it "builds a valid instance" do
      build(:wiki).should be_valid
    end
  end

  describe 'Snippet' do
    it "builds a valid instance" do
      build(:snippet).should be_valid
    end
  end
end
