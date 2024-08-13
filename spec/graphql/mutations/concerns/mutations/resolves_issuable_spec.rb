# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::ResolvesIssuable do
  include GraphqlHelpers

  let_it_be(:mutation_class) do
    Class.new(Mutations::BaseMutation) do
      include Mutations::ResolvesIssuable
    end
  end

  let_it_be(:project) { create(:project, :empty_repo) }
  let_it_be(:current_user) { create(:user) }
  let(:mutation) { mutation_class.new(object: nil, context: query_context, field: nil) }
  let(:parent) { issuable.project }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  context 'with issues' do
    let(:issuable) { issue }

    it_behaves_like 'resolving an issuable in GraphQL', :issue
  end

  context 'with merge requests' do
    let(:issuable) { merge_request }

    it_behaves_like 'resolving an issuable in GraphQL', :merge_request
  end
end
