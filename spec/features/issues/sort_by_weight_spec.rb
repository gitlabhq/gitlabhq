require 'spec_helper'

describe 'Issue sorting by Weight', feature: true do
  include SortingHelper

  let(:project) { create(:project, :public) }
  let(:foo) { create(:issue, title: 'foo', project: project) }
  let(:bar) { create(:issue, title: 'bar', project: project) }

  before do
    login_as :user
  end

  describe 'sorting by weight' do
    before do
      foo.update(weight: 5)
      bar.update(weight: 10)
    end

    it 'sorts by more weight' do
      visit namespace_project_issues_path(project.namespace, project, sort: sort_value_more_weight)

      expect(first_issue).to include('bar')
    end

    it 'sorts by less weight' do
      visit namespace_project_issues_path(project.namespace, project, sort: sort_value_less_weight)

      expect(first_issue).to include('foo')
    end
  end

  def first_issue
    page.all('ul.issues-list > li').first.text
  end
end
