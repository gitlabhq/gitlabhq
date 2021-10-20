# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Groups::Update do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:params) { { full_path: group.full_path } }

  specify { expect(described_class).to require_graphql_authorizations(:admin_group) }

  describe '#resolve' do
    subject { described_class.new(object: group, context: { current_user: user }, field: nil).resolve(**params) }

    RSpec.shared_examples 'updating the group shared runners setting' do
      it 'updates the group shared runners setting' do
        expect { subject }
          .to change { group.reload.shared_runners_setting }.from('enabled').to(Namespace::SR_DISABLED_AND_UNOVERRIDABLE)
      end

      it 'returns no errors' do
        expect(subject).to eq(errors: [], group: group)
      end

      context 'with invalid params' do
        let_it_be(:params) { { full_path: group.full_path, shared_runners_setting: 'inexistent_setting' } }

        it 'doesn\'t update the shared_runners_setting' do
          expect { subject }
            .not_to change { group.reload.shared_runners_setting }
        end

        it 'returns an error' do
          expect(subject).to eq(
            group: nil,
            errors: ["Update shared runners state must be one of: #{::Namespace::SHARED_RUNNERS_SETTINGS.join(', ')}"]
          )
        end
      end
    end

    RSpec.shared_examples 'denying access to group shared runners setting' do
      it 'raises Gitlab::Graphql::Errors::ResourceNotAvailable' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'changing shared runners setting' do
      let_it_be(:params) do
        { full_path: group.full_path,
          shared_runners_setting: Namespace::SR_DISABLED_AND_UNOVERRIDABLE }
      end

      where(:user_role, :shared_examples_name) do
        :owner      | 'updating the group shared runners setting'
        :developer  | 'denying access to group shared runners setting'
        :reporter   | 'denying access to group shared runners setting'
        :guest      | 'denying access to group shared runners setting'
        :anonymous  | 'denying access to group shared runners setting'
      end

      with_them do
        before do
          group.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end
  end
end
