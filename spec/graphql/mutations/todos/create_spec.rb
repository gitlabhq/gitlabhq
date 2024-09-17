# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Todos::Create do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  let(:current_user) { create(:user) }

  describe '#resolve' do
    context 'when target does not support todos' do
      it 'raises error' do
        target = create(:milestone)
        input = { target_id: global_id_of(target).to_s }
        mutation = graphql_mutation(described_class, input)
        headers = { "Referer" => "foobar", "User-Agent" => "user-agent" }
        request = instance_double(ActionDispatch::Request, headers: headers, env: nil)

        response = GitlabSchema.execute(
          mutation.query,
          context: query_context(request: request),
          variables: mutation.variables
        ).to_h

        expect(response).to include(
          'errors' => contain_exactly(
            include('message' => /invalid value for targetId/)
          )
        )
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
