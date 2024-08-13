# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotifyHelper, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

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

  describe '#merge_request_hash_param' do
    let(:merge_request) { create(:merge_request) }
    let(:reviewer) { create(:user) }
    let(:avatar_icon_for_user) { 'avatar_icon_for_user' }

    before do
      allow(helper).to receive(:avatar_icon_for_user).and_return(avatar_icon_for_user)
    end

    it 'returns MR approved description' do
      mr_link_style = "font-weight: 600;color:#3777b0;text-decoration:none"
      reviewer_avatar_style = "border-radius:12px;margin-left:3px;vertical-align:bottom;"
      mr_link = link_to(merge_request.to_reference, merge_request_url(merge_request), style: mr_link_style).html_safe
      reviewer_avatar = content_tag(
        :img,
        nil,
        height: "24",
        src: avatar_icon_for_user,
        style: reviewer_avatar_style,
        width: "24",
        alt: "Avatar",
        class: "avatar"
      ).html_safe
      reviewer_link = link_to(
        reviewer.name, user_url(reviewer), style: "color:#333333;text-decoration:none;", class: "muted"
      ).html_safe
      result = helper.merge_request_hash_param(merge_request, reviewer)
      expect(result[:mr_highlight]).to eq '<span style="font-weight: 600;color:#333333;">'.html_safe
      expect(result[:highlight_end]).to eq '</span>'.html_safe
      expect(result[:mr_link]).to eq mr_link
      expect(result[:reviewer_highlight]).to eq '<span>'.html_safe
      expect(result[:reviewer_avatar]).to eq reviewer_avatar
      expect(result[:reviewer_link]).to eq reviewer_link
    end
  end

  describe '#work_item_type_for' do
    where(:work_item, :expected_type) do
      build(:issue)              | 'issue'
      build(:issue, :task)       | 'issue'
      build(:issue, :test_case)  | 'issue'
      build(:issue, :key_result) | 'issue'
      build(:issue, :objective)  | 'issue'
      build(:issue, :ticket)     | 'issue'
      build(:incident)           | 'issue'
      build(:issue, :epic)       | 'epic'
    end

    with_them do
      it do
        expect(helper.work_item_type_for(work_item)).to eq(expected_type)
      end
    end
  end

  def reference_link(entity, url)
    "<a href=\"#{url}\">#{entity.to_reference}</a>"
  end
end
