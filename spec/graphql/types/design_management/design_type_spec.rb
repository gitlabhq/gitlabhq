# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Design'], feature_category: :portfolio_management do
  specify { expect(described_class.interfaces).to include(Types::CurrentUserTodos) }

  specify { expect(described_class.interfaces).to include(Types::TodoableInterface) }

  it_behaves_like 'a GraphQL type with design fields' do
    let(:extra_design_fields) do
      %i[notes current_user_todos discussions versions web_url
        commenters imported imported_from description descriptionHtml
        name]
    end

    let_it_be(:design) { create(:design, :with_versions) }
    let(:object_id) { GitlabSchema.id_from_object(design) }
    let_it_be(:object_id_b) { GitlabSchema.id_from_object(create(:design, :with_versions)) }
    let(:object_type) { ::Types::DesignManagement::DesignType }
  end
end
