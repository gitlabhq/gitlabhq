# frozen_string_literal: true

require 'pathname'
require 'open3'

# Checks for class name collisions between Database migrations and Elasticsearch migrations
class MigrationCollisionChecker
  MIGRATION_FOLDERS = %w[db/migrate/*.rb db/post_migrate/*.rb ee/elastic/migrate/*.rb].freeze

  CLASS_MATCHER = /^\s*class\s+:*([A-Z][A-Za-z0-9_]+\S+)/

  ERROR_CODE = 1

  Result = Struct.new(:error_code, :error_message)

  def initialize
    @collisions = Hash.new { |h, k| h[k] = [] }
  end

  def check
    check_for_collisions

    return if collisions.empty?

    Result.new(ERROR_CODE, "\e[31mError: Naming collisions were found between migrations\n\n#{message}\e[0m")
  end

  private

  attr_reader :collisions

  def check_for_collisions
    MIGRATION_FOLDERS.each do |migration_folder|
      Dir.glob(base_path.join(migration_folder)).each do |migration_path|
        klass_name = CLASS_MATCHER.match(File.read(migration_path))[1]
        collisions[klass_name] << migration_path
      end
    end

    collisions.select! { |_, v| v.size > 1 }
  end

  def message
    collisions.map { |klass_name, paths| "#{klass_name}: #{paths.join(', ')}\n" }.join('')
  end

  def base_path
    Pathname.new(File.expand_path('../../', __dir__))
  end
end
