#!/usr/bin/env ruby

# frozen_string_literal: true

# Taken from Jekyll
# https://github.com/jekyll/jekyll/blob/3.5-stable/lib/jekyll/document.rb#L13
YAML_FRONT_MATTER_REGEXP = /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m.freeze
READ_LIMIT_BYTES = 1024

require 'yaml'

def extract_front_matter(path)
  File.open(path, 'r') do |f|
    data = if match = YAML_FRONT_MATTER_REGEXP.match(f.read(READ_LIMIT_BYTES))
             YAML.safe_load(match[1])
           else
             {}
           end

    BlueprintFrontMatter.new(data)
  end
end

class BlueprintFrontMatter
  STATUSES = %w[proposed accepted ongoing implemented postponed rejected]

  attr_reader :errors

  def initialize(metadata)
    @metadata = metadata
    @errors = []
  end

  def validate
    return if @metadata['redirect_to']

    validate_status
    validate_authors
    validate_creation_date
  end

  private

  def validate_status
    status = @metadata['status']

    add_error('Missing status') unless status

    return if STATUSES.include?(status)

    add_error("Unsupported status '#{status}': expected one of '#{STATUSES.join(', ')}'")
  end

  def validate_authors
    authors = @metadata['authors']

    add_error('Missing authors') unless authors
    add_error('Authors must be an array') unless authors.is_a?(Array)
  end

  def validate_creation_date
    return if @metadata['creation-date'] =~ /\d{4}-[01]\d-[0123]\d/

    add_error("Invalid creation-date: the date format must be 'yyyy-mm-dd'")
  end

  def add_error(msg)
    @errors << msg
  end
end

if $PROGRAM_NAME == __FILE__
  exit_code = 0

  Dir['doc/architecture/blueprints/*/index.md'].each do |blueprint|
    meta = extract_front_matter(blueprint)
    meta.validate

    next if meta.errors.empty?

    exit_code = 1

    puts("✖ ERROR: Invalid #{blueprint}:")
    meta.errors.each { |e| puts(" - #{e}") }
  end

  exit(exit_code)
end
