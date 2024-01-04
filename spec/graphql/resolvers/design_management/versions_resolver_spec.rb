# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::DesignManagement::VersionsResolver do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  describe '#resolve' do
    let(:resolver) { described_class }
    let_it_be(:issue) { create(:issue) }
    let_it_be(:authorized_user) { create(:user) }
    let_it_be(:first_version) { create(:design_version, issue: issue) }
    let_it_be(:other_version) { create(:design_version, issue: issue) }
    let_it_be(:first_design) { create(:design, issue: issue, versions: [first_version, other_version]) }
    let_it_be(:other_design) { create(:design, :with_versions, issue: issue) }

    let(:project) { issue.project }
    let(:params) { {} }
    let(:current_user) { authorized_user }
    let(:query_context) { { current_user: current_user } }

    before do
      enable_design_management
      project.add_developer(authorized_user)
    end

    shared_examples 'a source of versions' do
      subject(:result) { resolve_versions(object)&.to_a }

      let_it_be(:all_versions) { object.versions.ordered }

      context 'when the user is not authorized' do
        let(:current_user) { create(:user) }

        it { is_expected.to be_empty }
      end

      context 'without constraints' do
        it 'returns the ordered versions' do
          expect(result.to_a).to eq(all_versions)
        end

        context 'loading associations' do
          it 'prevents N+1 queries when loading author' do
            control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
              resolve_versions(object).items.map(&:author)
            end

            create_list(:design_version, 3, issue: issue)

            expect do
              resolve_versions(object).items.map(&:author)
            end.not_to exceed_all_query_limit(control)
          end
        end
      end

      context 'when constrained' do
        let_it_be(:matching) { all_versions.earlier_or_equal_to(first_version) }

        shared_examples 'a query for all_versions up to the first_version' do
          it { is_expected.to eq(matching) }
        end

        context 'by earlier_or_equal_to_id' do
          let(:params) { { earlier_or_equal_to_id: global_id_of(first_version) } }

          it_behaves_like 'a query for all_versions up to the first_version'
        end

        context 'by earlier_or_equal_to_sha' do
          let(:params) { { earlier_or_equal_to_sha: first_version.sha } }

          it_behaves_like 'a query for all_versions up to the first_version'
        end

        context 'by earlier_or_equal_to_sha AND earlier_or_equal_to_id' do
          context 'and they match' do
            # This usage is rather dumb, but so long as they match, this will
            # return successfully
            let(:params) do
              {
                earlier_or_equal_to_sha: first_version.sha,
                earlier_or_equal_to_id: global_id_of(first_version)
              }
            end

            it_behaves_like 'a query for all_versions up to the first_version'
          end

          context 'and they do not match' do
            subject(:result) { resolve_versions(object) }

            let(:params) do
              {
                earlier_or_equal_to_sha: first_version.sha,
                earlier_or_equal_to_id: global_id_of(other_version)
              }
            end

            it 'generates a suitable error' do
              expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
                result
              end
            end
          end
        end
      end
    end

    describe 'a design collection' do
      let_it_be(:object) { DesignManagement::DesignCollection.new(issue) }

      it_behaves_like 'a source of versions'
    end

    describe 'a design' do
      let_it_be(:object) { first_design }

      it_behaves_like 'a source of versions'
    end

    def resolve_versions(obj)
      eager_resolve(resolver, obj: obj, args: params, ctx: query_context)
    end
  end
end
