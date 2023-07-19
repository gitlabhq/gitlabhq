# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Validators::MissingIndexes, feature_category: :database do
  missing_indexes = %w[
    missing_index
    index_namespaces_public_groups_name_id
    index_on_deploy_keys_id_and_type_and_public
    index_users_on_public_email_excluding_null_and_empty
  ]

  include_examples 'index validators', described_class, missing_indexes
end
