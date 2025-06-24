#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative '../config/environment'
require_relative 'click_house/schema_validator'

begin
  result = ClickHouse::SchemaValidator.validate!
  if result
    puts "\e[32mClickHouse schema is valid\e[0m"
    exit 0
  else
    puts "\e[31mClickHouse schema validation failed: schema file has uncommitted changes after migration\e[0m"
    exit 1
  end
rescue StandardError => e
  puts "\e[31mError during ClickHouse schema validation: #{e.message}\e[0m"
  exit 1
end
