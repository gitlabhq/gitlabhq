# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotifyHelper do
  include ActionView::Helpers::UrlHelper

  describe 'merge_request_reference_link' do
    let(:project) { create(:project) }
    let(:merge_request) { create(:merge_request, source_project: project) }

    it 'returns link to merge request with the text reference' do
      url = "http://test.host/#{project.full_path}/-/merge_requests/#{merge_request.iid}"

      expect(merge_request_reference_link(merge_request)).to eq(reference_link(merge_request, url))
    end
  end

  describe 'issue_reference_link' do
    let(:project) { create(:project) }
    let(:issue) { create(:issue, project: project) }

    it 'returns link to issue with the text reference' do
      url = "http://test.host/#{project.full_path}/-/issues/#{issue.iid}"

      expect(issue_reference_link(issue)).to eq(reference_link(issue, url))
    end
  end

  def reference_link(entity, url)
    "<a href=\"#{url}\">#{entity.to_reference}</a>"
  end
end
