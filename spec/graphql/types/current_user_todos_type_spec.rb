# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CurrentUserTodos'] do
  specify { expect(described_class.graphql_name).to eq('CurrentUserTodos') }

  specify { expect(described_class).to have_graphql_fields(:current_user_todos).only }
end
