# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Routing::OrganizationsHelper, feature_category: :organization do
  describe '.install' do
    it 'only installs once' do
      # Has already been installed as part of Rails initialization.
      # Second call should not reinstall
      expect(Rails.application.routes.url_helpers).not_to receive(:prepend)
      described_class::MappedHelpers.install
    end
  end

  describe '.build_route_pairs' do
    fake_route = Struct.new(:name)

    let(:global_routes) { [fake_route.new('admin_users')] }

    subject(:route_pairs) { described_class::MappedHelpers.build_route_pairs(organization_routes, global_routes) }

    context 'when the organization-scoped route shares a name with a global route' do
      let(:organization_routes) { [fake_route.new('organization_admin_users')] }

      it 'pairs the routes' do
        expect(route_pairs).to eq('admin_users' => 'organization_admin_users')
      end
    end

    context 'when no global route shares that name' do
      let(:organization_routes) { [fake_route.new('organization_nonexistent')] }

      it 'does not pair the routes' do
        expect(route_pairs).to eq({})
      end
    end
  end

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

    context 'when called outside of a request (e.g. a mailer or worker)' do
      it 'automatically routes to global path' do
        expect(helper_path).to eq(expected_global_path)
      end

      it 'automatically routes to global url' do
        expect(helper_url).to eq(expected_global_url)
      end
    end

    context 'when the request has no organization_path param' do
      before do
        allow(Current).to receive(:organization_resolver)
          .and_return(instance_double(Gitlab::Current::Organization, from_organization_params: nil))
      end

      it 'automatically routes to global path' do
        expect(helper_path).to eq(expected_global_path)
      end

      it 'automatically routes to global url' do
        expect(helper_url).to eq(expected_global_url)
      end
    end

    context 'when the request has an organization_path param' do
      # 'default' is deliberate - the previous scoped_paths?/default? check
      # broke exactly this case, treating the default Organization as never
      # scoped regardless of the request's own URL.
      let(:organization_path) { 'default' }

      let(:organization_helper_url) do
        public_send :"#{organization_helper}_url", organization_path: organization_path
      end

      let(:organization_helper_path) do
        public_send :"#{organization_helper}_path", organization_path: organization_path
      end

      before do
        organization = build_stubbed(:organization, path: organization_path)
        allow(Current).to receive(:organization_resolver)
          .and_return(instance_double(Gitlab::Current::Organization, from_organization_params: organization))
      end

      it 'automatically routes to organization scoped path' do
        expect(helper_path).to eq(organization_helper_path)
      end

      it 'automatically routes to organization scoped URL' do
        expect(helper_url).to eq(organization_helper_url)
      end

      context 'and called with organization_path: nil' do
        it 'routes to the global path despite the request URL' do
          expect(public_send(:"#{helper}_path", organization_path: nil)).to eq(expected_global_path)
        end
      end

      context 'and Current.data_context resolves to a different Organization' do
        let(:data_context_organization_path) { 'acme' }

        let(:data_context_organization_helper_path) do
          public_send :"#{organization_helper}_path", organization_path: data_context_organization_path
        end

        before do
          organization = build_stubbed(:organization, :isolated, path: data_context_organization_path)
          allow(Current).to receive(:data_context)
            .and_return(Gitlab::Current::DataContext.new(organization: organization))
        end

        it 'nests under Current.data_context rather than the request URL' do
          expect(helper_path).to eq(data_context_organization_helper_path)
        end

        it 'cannot be escaped by an explicit organization_path: nil override' do
          expect(public_send(:"#{helper}_path", organization_path: nil)).to eq(data_context_organization_helper_path)
        end
      end
    end

    context 'when there is no organization_path param but Current.data_context resolves to Organization context' do
      let(:organization_path) { 'acme' }

      let(:organization_helper_path) do
        public_send :"#{organization_helper}_path", organization_path: organization_path
      end

      before do
        organization = build_stubbed(:organization, :isolated, path: organization_path)
        allow(Current).to receive_messages(
          data_context: Gitlab::Current::DataContext.new(organization: organization),
          organization_resolver: instance_double(Gitlab::Current::Organization, from_organization_params: nil)
        )
      end

      it 'routes to the organization scoped path' do
        expect(helper_path).to eq(organization_helper_path)
      end

      context 'and called with organization_path: nil' do
        it 'still nests under Current.data_context - it cannot be escaped' do
          expect(public_send(:"#{helper}_path", organization_path: nil)).to eq(organization_helper_path)
        end
      end
    end

    context 'when neither the request URL nor Current.data_context resolve to Organization context' do
      before do
        allow(Current).to receive_messages(
          data_context: Gitlab::Current::DataContext.new,
          organization_resolver: instance_double(Gitlab::Current::Organization, from_organization_params: nil)
        )
      end

      it 'routes to the global path' do
        expect(helper_path).to eq(expected_global_path)
      end
    end
  end

  describe 'aliased unscoped url helpers' do
    include Rails.application.routes.url_helpers

    it 'aliases root_url as unscoped_root_url' do
      expect(root_url).to eq(unscoped_root_url)
    end

    it 'aliases root_path as unscoped_root_path' do
      expect(root_path).to eq(unscoped_root_path)
    end

    it 'aliases group_canonical_url as unscoped_group_canonical_url' do
      group = build_stubbed(:group)
      expect(group_canonical_url(group)).to eq(unscoped_group_canonical_url(group))
    end

    it 'aliases group_canonical_path as unscoped_group_canonical_path' do
      group = build_stubbed(:group)
      expect(group_canonical_path(group)).to eq(unscoped_group_canonical_path(group))
    end
  end

  describe '#root_path' do
    let(:helper) { :root }
    let(:organization_helper) { :organization_root }

    it_behaves_like 'organization aware route helper'
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

  describe '#dashboard_projects_path' do
    let(:helper) { :dashboard_projects }
    let(:organization_helper) { :organization_dashboard_projects }

    it_behaves_like 'organization aware route helper'
  end

  describe '#contributed_dashboard_projects_path' do
    let(:helper) { :contributed_dashboard_projects }
    let(:organization_helper) { :contributed_organization_dashboard_projects }

    it_behaves_like 'organization aware route helper'
  end

  describe '#starred_dashboard_projects_path' do
    let(:helper) { :starred_dashboard_projects }
    let(:organization_helper) { :starred_organization_dashboard_projects }

    it_behaves_like 'organization aware route helper'
  end

  describe '#personal_dashboard_projects_path' do
    let(:helper) { :personal_dashboard_projects }
    let(:organization_helper) { :personal_organization_dashboard_projects }

    it_behaves_like 'organization aware route helper'
  end

  describe '#member_dashboard_projects_path' do
    let(:helper) { :member_dashboard_projects }
    let(:organization_helper) { :member_organization_dashboard_projects }

    it_behaves_like 'organization aware route helper'
  end

  describe '#inactive_dashboard_projects_path' do
    let(:helper) { :inactive_dashboard_projects }
    let(:organization_helper) { :inactive_organization_dashboard_projects }

    it_behaves_like 'organization aware route helper'
  end

  describe '#dashboard_groups_path' do
    let(:helper) { :dashboard_groups }
    let(:organization_helper) { :organization_dashboard_groups }

    it_behaves_like 'organization aware route helper'
  end

  describe '#inactive_dashboard_groups_path' do
    let(:helper) { :inactive_dashboard_groups }
    let(:organization_helper) { :inactive_organization_dashboard_groups }

    it_behaves_like 'organization aware route helper'
  end
end
