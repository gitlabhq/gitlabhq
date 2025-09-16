# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Repository'], feature_category: :source_code_management do
  specify { expect(described_class.graphql_name).to eq('Repository') }

  specify { expect(described_class).to require_graphql_authorizations(:read_code) }

  specify { expect(described_class).to have_graphql_field(:root_ref) }

  specify { expect(described_class).to have_graphql_field(:tree) }

  specify { expect(described_class).to have_graphql_field(:last_commit) }

  specify { expect(described_class).to have_graphql_field(:paginated_tree, calls_gitaly?: true, max_page_size: 100) }

  specify { expect(described_class).to have_graphql_field(:exists, calls_gitaly?: true, complexity: 2) }

  specify { expect(described_class).to have_graphql_field(:blobs) }

  specify { expect(described_class).to have_graphql_field(:branch_names, calls_gitaly?: true, complexity: 170) }

  specify { expect(described_class).to have_graphql_field(:disk_path) }

  specify { expect(described_class).to have_graphql_field(:commit, calls_gitaly?: true) }

  specify do
    expect(described_class).to have_graphql_field(:commits, calls_gitaly?: true, max_page_size: 100)
  end
end
