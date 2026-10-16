# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Validators::DifferentDefinitionTables, feature_category: :database do
  include_examples 'table validators', described_class, %w[wrong_table wrong_partitioned_table]

  it 'reports the non-key column of a partitioned table' do
    inconsistency = result.find { |table| table.object_name == 'wrong_partitioned_table' }

    expect(inconsistency.structure_sql_statement)
      .to eq("CREATE TABLE wrong_partitioned_table (name character varying(255) NOT NULL)\n")
    expect(inconsistency.database_statement).to eq("CREATE TABLE wrong_partitioned_table (name text NOT NULL)\n")
  end
end
