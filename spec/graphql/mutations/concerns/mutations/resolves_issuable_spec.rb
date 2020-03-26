# frozen_string_literal: true

require 'spec_helper'

describe Mutations::ResolvesIssuable do
  let_it_be(:mutation_class) do
    Class.new(Mutations::BaseMutation) do
      include Mutations::ResolvesIssuable
    end
  end

  let_it_be(:project)  { create(:project) }
  let_it_be(:user)     { create(:user) }
  let_it_be(:context)  { { current_user: user } }
  let_it_be(:mutation) { mutation_class.new(object: nil, context: context, field: nil) }
  let(:parent) { issuable.project }

  context 'with issues' do
    let(:issuable) { create(:issue, project: project) }

    it_behaves_like 'resolving an issuable in GraphQL', :issue
  end

  context 'with merge requests' do
    let(:issuable) { create(:merge_request, source_project: project) }

    it_behaves_like 'resolving an issuable in GraphQL', :merge_request
  end
end
