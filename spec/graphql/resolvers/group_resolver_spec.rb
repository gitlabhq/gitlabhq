# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::GroupResolver do
  include GraphqlHelpers

  it_behaves_like 'a resolver that batch resolves by full path' do
    let_it_be(:entity1) { create(:group) }
    let_it_be(:entity2) { create(:group) }
    let_it_be(:resolve_method) { :resolve_group }
  end

  def resolve_group(full_path)
    resolve(described_class, args: { full_path: full_path })
  end
end
