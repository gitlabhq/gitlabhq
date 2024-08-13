#!/usr/bin/env ruby
# frozen_string_literal: true

# Update group name in all relevant metric and event definition after a group name change.

require 'json'
PRODUCT_GROUPS_SCHEMA_PATH = 'config/metrics/schema/product_groups.json'
ALL_METRIC_AND_EVENT_DEFINITIONS_GLOB = "{ee/,}config/{metrics/*,events}/*.yml"

class ProductGroupRenamer
  def initialize(schema_path, definitions_glob)
    @schema_path = schema_path
    @definitions_glob = definitions_glob
  end

  def rename_product_group(old_name, new_name)
    changed_files = []
    # Rename the product group in the schema

    current_schema = File.read(@schema_path)
    product_group_schema = JSON.parse(current_schema)

    product_group_schema["enum"].delete(old_name)
    product_group_schema["enum"].push(new_name) unless product_group_schema["enum"].include?(new_name)
    product_group_schema["enum"].sort!

    new_schema = "#{JSON.pretty_generate(product_group_schema)}\n"
    if new_schema != current_schema
      File.write(@schema_path, new_schema)
      changed_files << @schema_path
    end

    # Rename product group in all metric and event definitions
    Dir.glob(@definitions_glob).each do |file_path|
      file_content = File.read(File.expand_path(file_path))

      new_content = file_content.gsub(/product_group:\s*['"]?#{old_name}['"]?$/, "product_group: #{new_name}")

      if new_content != file_content
        File.write(file_path, new_content)
        changed_files << file_path
      end
    end

    changed_files
  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV.length != 2
    puts <<~TEXT
    Usage:
      When a group is renamed, this script replaces the value for "product_group" in all matching event & metric definitions.

    Format:
      #{$PROGRAM_NAME} OLD_NAME NEW_NAME

    Example:
      #{$PROGRAM_NAME} pipeline_authoring renamed_pipeline_authoring
    TEXT
    exit
  end

  old_name = ARGV[0]
  new_name = ARGV[1]

  changed_files = ProductGroupRenamer
    .new(PRODUCT_GROUPS_SCHEMA_PATH, ALL_METRIC_AND_EVENT_DEFINITIONS_GLOB)
    .rename_product_group(old_name, new_name)

  puts "Updated '#{old_name}' to '#{new_name}' in #{changed_files.length} files"
  puts

  if changed_files.any?
    puts "Updated files:"
    changed_files.each do |file_path|
      puts "  #{file_path}"
    end
  end
end
