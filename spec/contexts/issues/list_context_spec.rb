require 'spec_helper'

describe Issues::ListContext do

  let(:user) { create(:user) }
  let(:project) { create(:project, creator: user) }

  titles = ['foo','bar','baz']
  titles.each_with_index do |title, index|
    let!(title.to_sym) { create(:issue, title: title, project: project, created_at: Time.now - (index * 60)) }
  end

  describe 'sorting' do
    it 'sorts by newest' do
      params = {sort: 'newest'}

      issues = Issues::ListContext.new(project, user, params).execute
      issues.first.should eq foo
    end

    it 'sorts by oldest' do
      params = {sort: 'oldest'}

      issues = Issues::ListContext.new(project, user, params).execute
      issues.first.should eq baz
    end

    it 'sorts by recently updated' do
      params = {sort: 'recently_updated'}
      baz.updated_at = Time.now + 10
      baz.save

      issues = Issues::ListContext.new(project, user, params).execute
      issues.first.should eq baz
    end

    it 'sorts by least recently updated' do
      params = {sort: 'last_updated'}
      bar.updated_at = Time.now - 10
      bar.save

      issues = Issues::ListContext.new(project, user, params).execute
      issues.first.should eq bar
    end

    describe 'sorting by milestone' do
      let(:newer_due_milestone) { create(:milestone, due_date: '2013-12-11') }
      let(:later_due_milestone) { create(:milestone, due_date: '2013-12-12') }

      before :each do
        foo.milestone = newer_due_milestone
        foo.save
        bar.milestone = later_due_milestone
        bar.save
      end

      it 'sorts by most recently due milestone' do
        params = {sort: 'milestone_due_soon'}

        issues = Issues::ListContext.new(project, user, params).execute
        issues.first.should eq foo

      end

      it 'sorts by least recently due milestone' do
        params = {sort: 'milestone_due_later'}

        issues = Issues::ListContext.new(project, user, params).execute
        issues.first.should eq bar
      end
    end
  end
end
