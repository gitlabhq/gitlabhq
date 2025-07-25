# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Routing::OrganizationsHelper, feature_category: :organization do
  shared_examples 'organization aware route helper' do
    include Rails.application.routes.url_helpers

    let(:helper_url) { public_send :"#{helper}_url" }
    let(:helper_path) { public_send :"#{helper}_path" }

    let(:expected_global_path) do
      # Call the method on a fresh url_helpers instance to get the original behavior
      original_helpers = Rails.application.routes.url_helpers.dup
      original_helpers.public_send(:"#{helper}_path")
    end

    let(:expected_global_url) { "http://test.host#{expected_global_path}" }

    context 'when organization context is not present' do
      before do
        allow(Current).to receive_messages(organization_assigned: false, organization: nil)
      end

      it 'automatically routes to global path' do
        expect(helper_path).to eq(expected_global_path)
      end

      it 'automatically routes to global url' do
        expect(helper_url).to eq(expected_global_url)
      end
    end

    context 'when organization has path scopes' do
      let(:organization) { build_stubbed(:organization) }

      let(:organization_helper_url) do
        public_send :"#{organization_helper}_url", organization_path: organization.path
      end

      let(:organization_helper_path) do
        public_send :"#{organization_helper}_path", organization_path: organization.path
      end

      before do
        allow(Current).to receive_messages(organization_assigned: true, organization: organization)
      end

      context 'and they are enabled' do
        before do
          allow(organization).to receive(:scoped_paths?).and_return(true)
        end

        it 'automatically routes to organization scoped path' do
          expect(helper_path).to eq(organization_helper_path)
        end

        it 'automatically routes to organization scoped URL' do
          expect(helper_url).to eq(organization_helper_url)
        end
      end

      context 'and they are disabled' do
        before do
          allow(organization).to receive(:scoped_paths?).and_return(false)
        end

        it 'automatically routes to global path' do
          expect(helper_path).to eq(expected_global_path)
        end

        it 'automatically routes to global url' do
          expect(helper_url).to eq(expected_global_url)
        end
      end
    end

    context 'when organization context is nil' do
      before do
        allow(Current).to receive_messages(organization_assigned: true, organization: nil)
      end

      it 'automatically routes to global path' do
        expect(helper_path).to eq(expected_global_path)
      end

      it 'automatically routes to global URL' do
        expect(helper_url).to eq(expected_global_url)
      end
    end
  end

  describe '.install' do
    it 'only installs once' do
      # Has already been installed as part of Rails initialization.
      # Second call should not reinstall
      expect(Rails.application.routes.url_helpers).not_to receive(:prepend)
      described_class::MappedHelpers.install
    end
  end

  describe '#new_project_path' do
    let(:helper) { :new_project }
    let(:organization_helper) { :new_organization_project }

    it_behaves_like 'organization aware route helper'
  end

  describe '#projects_path' do
    let(:helper) { :projects }
    let(:organization_helper) { :organization_projects }

    it_behaves_like 'organization aware route helper'
  end

  describe '#new_group_path' do
    let(:helper) { :new_group }
    let(:organization_helper) { :new_organization_group }

    it_behaves_like 'organization aware route helper'
  end

  describe '#groups_path' do
    let(:helper) { :groups }
    let(:organization_helper) { :organization_groups }

    it_behaves_like 'organization aware route helper'
  end
end
