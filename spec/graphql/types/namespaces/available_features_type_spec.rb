# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::AvailableFeaturesType, feature_category: :shared do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }

  shared_examples "a type that resolves available features" do
    context 'when the issue_date_filter feature flag is enabled' do
      before do
        stub_feature_flags(issue_date_filter: true)
      end

      it 'returns true' do
        expect(resolve_field(:has_issue_date_filter_feature, namespace, current_user: user)).to be(true)
      end
    end

    context 'when the issue_date_filter feature flag is disabled' do
      before do
        stub_feature_flags(issue_date_filter: false)
      end

      it 'returns false' do
        expect(resolve_field(:has_issue_date_filter_feature, namespace, current_user: user)).to be(false)
      end
    end
  end

  context 'with a group namespace' do
    it_behaves_like 'a type that resolves available features' do
      let_it_be(:namespace) { create(:group) }
    end
  end

  context 'with a project namespace' do
    it_behaves_like 'a type that resolves available features' do
      let_it_be(:namespace) { create(:project_namespace) }
    end
  end

  context 'with a user namespace' do
    it_behaves_like 'a type that resolves available features' do
      let_it_be(:namespace) { create(:user_namespace) }
    end
  end

  describe '#has_work_item_planning_view_feature' do
    context 'when namespace is a group' do
      let_it_be(:namespace) { create(:group) }

      it 'delegates to work_items_consolidated_list_enabled?' do
        allow(namespace).to receive(:work_items_consolidated_list_enabled?).with(user).and_return(true)

        expect(resolve_field(:has_work_item_planning_view_feature, namespace, current_user: user)).to be(true)
      end
    end

    context 'when namespace is a project namespace' do
      let_it_be(:project) { create(:project) }
      let_it_be(:namespace) { project.project_namespace }

      it 'delegates to project.work_items_consolidated_list_enabled?' do
        allow(project).to receive(:work_items_consolidated_list_enabled?).with(user).and_return(true)

        expect(resolve_field(:has_work_item_planning_view_feature, namespace, current_user: user)).to be(true)
      end
    end

    context 'when namespace is a user namespace' do
      let_it_be(:namespace) { create(:user_namespace) }

      context 'when WIP feature flag is enabled' do
        before do
          stub_feature_flags(work_item_planning_view: true)
        end

        it 'returns true' do
          expect(resolve_field(:has_work_item_planning_view_feature, namespace, current_user: user)).to be(true)
        end
      end

      context 'when WIP feature flag is disabled' do
        before do
          stub_feature_flags(work_item_planning_view: false)
        end

        context 'when user flag is enabled for current user' do
          before do
            stub_feature_flags(work_items_consolidated_list_user: user)
          end

          it 'returns true' do
            expect(resolve_field(:has_work_item_planning_view_feature, namespace, current_user: user)).to be(true)
          end
        end

        context 'when user flag is disabled' do
          before do
            stub_feature_flags(work_items_consolidated_list_user: false)
          end

          it 'returns false' do
            expect(resolve_field(:has_work_item_planning_view_feature, namespace, current_user: user)).to be(false)
          end
        end

        context 'when current_user is nil' do
          let(:user) { nil }

          before do
            stub_feature_flags(work_items_consolidated_list_user: true)
          end

          it 'returns false' do
            expect(resolve_field(:has_work_item_planning_view_feature, namespace, current_user: user)).to be(false)
          end
        end
      end
    end
  end

  it_behaves_like 'expose all available feature fields for the namespace'
end
