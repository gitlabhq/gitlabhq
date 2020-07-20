# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DashboardHelper do
  let(:user) { build(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
    allow(helper).to receive(:can?) { true }
  end

  describe '#dashboard_nav_links' do
    it 'has all the expected links by default' do
      menu_items = [:projects, :groups, :activity, :milestones, :snippets]

      expect(helper.dashboard_nav_links).to include(*menu_items)
    end

    it 'does not contain cross project elements when the user cannot read cross project' do
      expect(helper).to receive(:can?).with(user, :read_cross_project) { false }

      expect(helper.dashboard_nav_links).not_to include(:activity, :milestones)
    end
  end

  describe '#feature_entry' do
    shared_examples "a feature is enabled" do
      it { is_expected.to include('<p aria-label="Demo: status on">') }
    end

    shared_examples "a feature is disabled" do
      it { is_expected.to include('<p aria-label="Demo: status off">') }
    end

    shared_examples "a feature without link" do
      it do
        is_expected.not_to have_link('Demo')
        is_expected.not_to have_link('Documentation')
      end
    end

    shared_examples "a feature with configuration" do
      it { is_expected.to have_link('Demo', href: 'demo.link') }
    end

    shared_examples "a feature with documentation" do
      it { is_expected.to have_link('Documentation', href: 'doc.link') }
    end

    context 'when implicitly enabled' do
      subject { feature_entry('Demo') }

      it_behaves_like 'a feature is enabled'
    end

    context 'when explicitly enabled' do
      context 'without links' do
        subject { feature_entry('Demo', enabled: true) }

        it_behaves_like 'a feature is enabled'
        it_behaves_like 'a feature without link'
      end

      context 'with configure link' do
        subject { feature_entry('Demo', href: 'demo.link', enabled: true) }

        it_behaves_like 'a feature with configuration'
      end

      context 'with configure and documentation links' do
        subject { feature_entry('Demo', href: 'demo.link', doc_href: 'doc.link', enabled: true) }

        it_behaves_like 'a feature with configuration'
        it_behaves_like 'a feature with documentation'
      end
    end

    context 'when disabled' do
      subject { feature_entry('Demo', href: 'demo.link', enabled: false) }

      it_behaves_like 'a feature is disabled'
      it_behaves_like 'a feature without link'
    end
  end

  describe '.has_start_trial?' do
    subject { helper.has_start_trial? }

    it { is_expected.to eq(false) }
  end
end
