# frozen_string_literal: true

namespace :db do
  namespace :relationships do
    desc "Print database relationships in JSON format"
    task all: :environment do
      builder = Gitlab::Reflections::Relationships::Builder.new
      relationships = builder.build_relationships

      puts Gitlab::Json.pretty_generate(relationships)
    end
  end
end
