# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Timelogs::Delete do
  include GraphqlHelpers

  let_it_be(:author) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:administrator) { create(:user, :admin) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be_with_reload(:timelog) { create(:timelog, user: author, issue: issue, time_spent: 1800) }

  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }
  let(:timelog_id) { global_id_of(timelog) }
  let(:mutation_arguments) { { id: timelog_id } }

  describe '#resolve' do
    subject(:resolve) do
      mutation.resolve(**mutation_arguments)
    end

    context 'when the timelog id is not valid' do
      let(:current_user) { author }
      let(:timelog_id) { global_id_of(model_name: 'Timelog', id: non_existing_record_id) }

      it 'raises Gitlab::Graphql::Errors::ResourceNotAvailable' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the current user is not the timelog\'s author, not a maintainer and not an admin' do
      let(:current_user) { create(:user) }

      it 'raises Gitlab::Graphql::Errors::ResourceNotAvailable' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the current user is the timelog\'s author' do
      let(:current_user) { author }

      it 'deletes the timelog' do
        expect { subject }.to change { Timelog.count }.by(-1)
      end

      it 'returns the deleted timelog' do
        expect(subject[:timelog]).to eq(timelog)
      end

      it 'returns no errors' do
        expect(subject[:errors]).to be_empty
      end
    end

    context 'when the current user is not the timelog\'s author but a maintainer of the project' do
      let(:current_user) { maintainer }

      before do
        project.add_maintainer(maintainer)
      end

      it 'deletes the timelog' do
        expect { subject }.to change { Timelog.count }.by(-1)
      end

      it 'returns the deleted timelog' do
        expect(subject[:timelog]).to eq(timelog)
      end

      it 'returns no errors' do
        expect(subject[:errors]).to be_empty
      end
    end

    context 'when the current user is not the timelog\'s author, not a maintainer but an admin', :enable_admin_mode do
      let(:current_user) { administrator }

      it 'deletes the timelog' do
        expect { subject }.to change { Timelog.count }.by(-1)
      end

      it 'returns the deleted timelog' do
        expect(subject[:timelog]).to eq(timelog)
      end

      it 'returns no errors' do
        expect(subject[:errors]).to be_empty
      end
    end
  end
end
