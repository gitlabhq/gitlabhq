# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Avoid Migration Name Collisions', feature_category: :database do
  subject(:duplicated_migration_class_names) do
    class_names = migration_files.map { |path| class_name_regex.match(File.read(path))[1] }
    class_names.select { |class_name| class_names.count(class_name) > 1 }
  end

  let(:class_name_regex) { /^\s*class\s+:*([A-Z][A-Za-z0-9_]+\S+)/ }
  let(:migration_files) { Dir['db/migrate/*.rb', 'db/post_migrate/*.rb', 'ee/elastic/migrate/*.rb'] }

  it 'loads all database and search migrations without name collisions' do
    expect(duplicated_migration_class_names).to be_empty
  end
end
