# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Todos::Create do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  describe '#resolve' do
    context 'when target does not support todos' do
      it 'raises error' do
        current_user = create(:user)
        mutation = described_class.new(object: nil, context: { current_user: current_user }, field: nil)

        target = create(:milestone)

        expect { mutation.resolve(target_id: global_id_of(target)) }
          .to raise_error(GraphQL::CoercionError)
      end
    end

    context 'with issue as target' do
      it_behaves_like 'create todo mutation' do
        let_it_be(:target) { create(:issue) }
      end
    end

    context 'with merge request as target' do
      it_behaves_like 'create todo mutation' do
        let_it_be(:target) { create(:merge_request) }
      end
    end

    context 'with design as target' do
      before do
        enable_design_management
      end

      it_behaves_like 'create todo mutation' do
        let_it_be(:target) { create(:design) }
      end
    end
  end
end
