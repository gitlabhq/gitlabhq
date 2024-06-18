# frozen_string_literal: true

require 'parser/current'
require 'json'

load 'gems/gitlab-utils/lib/gitlab/version_info.rb'
load 'lib/gitlab/database/migrations/version.rb'

# We need this as Gitlab::VersionInfo depends on #present?
class Object
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end

  def present?
    !blank?
  end
end

def evaluate_node(ast)
  return unless ast.is_a?(Parser::AST::Node)

  if ast.type == :send
    _, method, *args = ast.children
    return args.first.children.first if method == :milestone && args.any?
  else
    ast.children.each do |child|
      result = evaluate_node(child)
      return result if result
    end
  end

  nil
end

def find_milestone(filename)
  code = File.read(filename)
  ast = Parser::CurrentRuby.parse(code)
  evaluate_node(ast)
end

def grep_timestamp(filename)
  File.basename(filename).match(/(?<timestamp>\d+)_.*\.rb/)[:timestamp].to_i
end

def grep_type(filename)
  filename.include?('/post_migrate/') ? :post : :regular
end

def version_from_file(filename)
  timestamp = grep_timestamp(filename)
  milestone = find_milestone(filename)
  if milestone.present?
    type = grep_type(filename)

    Gitlab::Database::Migrations::Version.new(timestamp, milestone, type)
  else
    timestamp
  end
end

codebase_versions = Dir['db/migrate/*.rb', 'db/post_migrate/*.rb'].map do |filename|
  version_from_file(filename)
end.sort.reverse

geo_codebase_versions = Dir['ee/db/geo/migrate/*.rb', 'ee/db/geo/post_migrate/*.rb'].map do |filename|
  version_from_file(filename)
end.sort.reverse

result = {
  migrations: {
    regular: codebase_versions.find { |v| v.is_a?(Gitlab::Database::Migrations::Version) && v.type == :regular },
    all: codebase_versions.first
  },
  geo_migrations: {
    regular: geo_codebase_versions.find { |v| v.is_a?(Gitlab::Database::Migrations::Version) && v.type == :regular },
    all: geo_codebase_versions.first
  }
}

print(result.to_json)
