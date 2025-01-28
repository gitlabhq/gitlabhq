# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DashboardHelper do
  let(:user) { build(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
    allow(helper).to receive(:can?) { true }
  end

  describe '#feature_entry' do
    shared_examples "a feature is enabled" do
      it { is_expected.to include('<p aria-label="Demo: enabled" class="gl-py-4 gl-m-0 gl-border-b">') }
    end

    shared_examples "a feature is disabled" do
      it { is_expected.to include('<p aria-label="Demo: not enabled" class="gl-py-4 gl-m-0 gl-border-b">') }
    end

    shared_examples "a feature without link" do
      it do
        is_expected.not_to have_link('Configure')
        is_expected.not_to have_link('Documentation')
      end
    end

    shared_examples "a feature with configuration" do
      it { is_expected.to have_link('Configure', href: 'demo.link') }
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
      it_behaves_like 'a feature with configuration'
    end
  end

  describe '.has_start_trial?' do
    subject { helper.has_start_trial? }

    it { is_expected.to eq(false) }
  end

  describe '.user_groups_requiring_reauth', feature_category: :system_access do
    it 'returns an empty array' do
      expect(helper.user_groups_requiring_reauth).to be_empty
    end
  end

  describe '.user_roles_mapping' do
    it 'returns roles mapping' do
      expect(helper.user_roles_mapping).to match({
        planner: 'Planner',
        reporter: 'Reporter',
        developer: 'Developer',
        maintainer: 'Maintainer',
        owner: 'Owner',
        guest: 'Guest'
      })
    end
  end
end
