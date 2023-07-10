# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::SchemaObjects::Index, feature_category: :database do
  let(:statement) { 'CREATE INDEX index_name ON public.achievements USING btree (namespace_id)' }
  let(:name) { 'index_name' }
  let(:table_name) { 'achievements' }

  include_examples 'schema objects assertions for', 'index_stmt'
end
