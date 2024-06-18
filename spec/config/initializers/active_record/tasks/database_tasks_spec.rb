# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveRecord::Tasks::DatabaseTasks, feature_category: :database do
  let(:db_config) { Gitlab::Database.database_base_models.first }

  it 'does not raise an error' do
    expect { described_class.migrate_status }.not_to raise_error
  end
end
