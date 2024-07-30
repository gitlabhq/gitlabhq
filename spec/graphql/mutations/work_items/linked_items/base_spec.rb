# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::WorkItems::LinkedItems::Base, feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: current_user) }
  let_it_be(:work_item) { create(:work_item, project: project) }

  it 'raises a NotImplementedError error if the update_links method is called on the base class' do
    mutation = described_class.new(context: query_context, object: nil, field: nil)

    expect { mutation.resolve(id: work_item.to_gid) }
      .to raise_error(NotImplementedError, "#{described_class} does not implement update_links")
  end
end
