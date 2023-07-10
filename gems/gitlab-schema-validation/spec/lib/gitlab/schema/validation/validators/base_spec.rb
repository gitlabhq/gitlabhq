# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Schema::Validation::Validators::Base do
  describe '#execute' do
    let(:structure_sql) { instance_double(Gitlab::Schema::Validation::Sources::StructureSql) }
    let(:database) { instance_double(Gitlab::Schema::Validation::Sources::Database) }

    subject(:inconsistencies) { described_class.new(structure_sql, database).execute }

    it 'raises an exception' do
      expect { inconsistencies }.to raise_error(NoMethodError)
    end
  end
end
