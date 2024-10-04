# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::ContainerExpirationPolicies::Update, feature_category: :container_registry do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let(:container_expiration_policy) { project.container_expiration_policy }
  let(:params) { { project_path: project.full_path, cadence: '3month', keep_n: 100, older_than: '14d' } }

  specify { expect(described_class).to require_graphql_authorizations(:admin_container_image) }

  describe '#resolve' do
    subject { described_class.new(object: project, context: query_context, field: nil).resolve(**params) }

    RSpec.shared_examples 'returning a success' do
      it 'returns the container expiration policy with no errors' do
        expect(subject).to eq(
          container_expiration_policy: container_expiration_policy,
          container_tags_expiration_policy: container_expiration_policy,
          errors: []
        )
      end
    end

    RSpec.shared_examples 'updating the container expiration policy' do
      it_behaves_like 'updating the container expiration policy attributes', mode: :update, from: { cadence: '1d', keep_n: 10, older_than: '90d' }, to: { cadence: '3month', keep_n: 100, older_than: '14d' }

      it_behaves_like 'returning a success'

      context 'with invalid params' do
        let_it_be(:params) { { project_path: project.full_path, cadence: '20d' } }

        it_behaves_like 'not creating the container expiration policy'

        it 'doesn\'t update the cadence' do
          expect { subject }
            .not_to change { container_expiration_policy.reload.cadence }
        end

        it 'returns an error' do
          expect(subject).to eq(
            container_expiration_policy: nil,
            container_tags_expiration_policy: nil,
            errors: ['Cadence is not included in the list']
          )
        end
      end

      context 'with blank regex' do
        let_it_be(:params) { { project_path: project.full_path, name_regex: '', enabled: true } }

        it_behaves_like 'not creating the container expiration policy'

        it "doesn't update the cadence" do
          expect { subject }
            .not_to change { container_expiration_policy.reload.cadence }
        end

        it 'returns an error' do
          expect(subject).to eq(
            container_expiration_policy: nil,
            container_tags_expiration_policy: nil,
            errors: ['Name regex can\'t be blank']
          )
        end
      end
    end

    RSpec.shared_examples 'denying access to container expiration policy' do
      it 'raises Gitlab::Graphql::Errors::ResourceNotAvailable' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'with existing container expiration policy' do
      where(:user_role, :shared_examples_name) do
        :maintainer | 'updating the container expiration policy'
        :developer  | 'denying access to container expiration policy'
        :reporter   | 'denying access to container expiration policy'
        :guest      | 'denying access to container expiration policy'
        :anonymous  | 'denying access to container expiration policy'
      end

      with_them do
        before do
          project.send("add_#{user_role}", current_user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end

    context 'without existing container expiration policy' do
      let_it_be(:project, reload: true) { create(:project, :without_container_expiration_policy) }

      where(:user_role, :shared_examples_name) do
        :maintainer | 'creating the container expiration policy'
        :developer  | 'denying access to container expiration policy'
        :reporter   | 'denying access to container expiration policy'
        :guest      | 'denying access to container expiration policy'
        :anonymous  | 'denying access to container expiration policy'
      end

      with_them do
        before do
          project.send("add_#{user_role}", current_user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end
  end
end
