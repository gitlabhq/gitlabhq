# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NavHelper, feature_category: :navigation do
  describe '.admin_monitoring_nav_links' do
    subject { helper.admin_monitoring_nav_links }

    it { is_expected.to all(be_a(String)) }
  end

  describe '#page_has_markdown?' do
    using RSpec::Parameterized::TableSyntax

    where path: %w[
      projects/merge_requests#show
      projects/merge_requests/conflicts#show
      issues#show
      milestones#show
      issues#designs
    ]

    with_them do
      before do
        allow(helper).to receive(:current_path?).and_call_original
        allow(helper).to receive(:current_path?).with(path).and_return(true)
      end

      subject { helper.page_has_markdown? }

      it { is_expected.to eq(true) }
    end
  end

  describe '#super_sidebar_loading_state_class' do
    context 'when super_sidebar_collapsed cookie is true' do
      before do
        helper.request.cookies['super_sidebar_collapsed'] = 'true'
      end

      it 'returns super-sidebar-is-icon-only class' do
        expect(helper.super_sidebar_loading_state_class).to eq('super-sidebar-is-icon-only')
      end
    end

    context 'when super_sidebar_collapsed cookie is false' do
      before do
        helper.request.cookies['super_sidebar_collapsed'] = 'false'
      end

      it 'returns empty string' do
        expect(helper.super_sidebar_loading_state_class).to eq('')
      end
    end

    context 'when super_sidebar_collapsed cookie is not set' do
      it 'returns empty string' do
        expect(helper.super_sidebar_loading_state_class).to eq('')
      end
    end
  end
end
