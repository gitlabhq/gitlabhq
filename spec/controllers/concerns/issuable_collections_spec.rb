require 'spec_helper'

describe IssuableCollections do
  let(:user) { create(:user) }

  let(:controller) do
    klass = Class.new do
      def self.helper_method(name); end

      include IssuableCollections
    end

    controller = klass.new

    allow(controller).to receive(:params).and_return(state: 'opened')

    controller
  end

  describe '#redirect_out_of_range' do
    before do
      allow(controller).to receive(:url_for)
    end

    it 'returns true and redirects if the offset is out of range' do
      relation = double(:relation, current_page: 10)

      expect(controller).to receive(:redirect_to)
      expect(controller.send(:redirect_out_of_range, relation, 2)).to eq(true)
    end

    it 'returns false if the offset is not out of range' do
      relation = double(:relation, current_page: 1)

      expect(controller).not_to receive(:redirect_to)
      expect(controller.send(:redirect_out_of_range, relation, 2)).to eq(false)
    end
  end

  describe '#issues_page_count' do
    it 'returns the number of issue pages' do
      project = create(:project, :public)

      create(:issue, project: project)

      finder = IssuesFinder.new(user)
      issues = finder.execute

      allow(controller).to receive(:issues_finder)
        .and_return(finder)

      expect(controller.send(:issues_page_count, issues)).to eq(1)
    end
  end

  describe '#merge_requests_page_count' do
    it 'returns the number of merge request pages' do
      project = create(:project, :public)

      create(:merge_request, source_project: project, target_project: project)

      finder = MergeRequestsFinder.new(user)
      merge_requests = finder.execute

      allow(controller).to receive(:merge_requests_finder)
        .and_return(finder)

      pages = controller.send(:merge_requests_page_count, merge_requests)

      expect(pages).to eq(1)
    end
  end

  describe '#page_count_for_relation' do
    it 'returns the number of pages' do
      relation = double(:relation, limit_value: 20)
      pages = controller.send(:page_count_for_relation, relation, 28)

      expect(pages).to eq(2)
    end
  end
end
