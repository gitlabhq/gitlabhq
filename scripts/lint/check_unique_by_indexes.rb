#!/usr/bin/env ruby
# frozen_string_literal: true

#
# This script detects unique_by declarations that reference indexes not available at deploy time.
#
# A unique_by declaration is safe if:
# 1. The index already exists in the base branch's db/structure.sql (already deployed), OR
# 2. The index is being added in db/migrate/ in this MR (runs before code deployment)
#
# A unique_by declaration is UNSAFE if:
# 1. The index only exists in db/post_migrate/ (runs after code deployment), OR
# 2. The index doesn't exist anywhere (missing index)
#
# See: INC-9604
#

require 'open3'

class UniqueByIndexChecker
  UNIQUE_BY_PATTERNS = [
    /unique_by[=:\s]+%[iIwW]\[([^\]]+)\]/,
    /unique_by:\s*\[\s*:([^\]]+)\]/,
    /unique_by:\s*:(\w+)/
  ].freeze

  MIGRATE_INDEX_PATTERNS = [
    /add_concurrent_index\s+:\w+,\s*%[iIwW]\[([^\]]+)\][^}]*unique:\s*true/m,
    /add_concurrent_index\s+:\w+,\s*\[\s*:([^\]]+)\][^}]*unique:\s*true/m,
    /add_concurrent_index\s+:\w+,\s*:(\w+)[^,]*,\s*unique:\s*true/
  ].freeze

  STRUCTURE_SQL_PATTERNS = [
    /CREATE UNIQUE INDEX\s+\S+\s+ON\s+(?:ONLY\s+)?(\S+)\s+USING\s+\w+\s*\(([^)]+)\)/i,
    /ADD CONSTRAINT\s+\S+\s+UNIQUE\s*\(([^)]+)\)/i
  ].freeze

  def initialize
    @errors = []
  end

  def run
    return 0 if changed_files.empty?

    code_files = changed_files.select { |f| code_file?(f) }
    return 0 if code_files.empty?

    new_unique_bys = extract_unique_by_from_diff(code_files)
    return 0 if new_unique_bys.empty?

    base_indexes = extract_indexes_from_base_schema
    migrate_indexes = extract_indexes_from_migrate_files

    safe_indexes = base_indexes + migrate_indexes

    check_violations(new_unique_bys, safe_indexes)

    if @errors.any?
      print_errors
      1
    else
      puts "No unique_by/index deployment issues detected."
      0
    end
  end

  private

  def changed_files
    @changed_files ||= run_git_command('diff', '--name-only', "#{base_ref}...HEAD").split("\n")
  end

  def base_ref
    @base_ref ||= ENV.fetch('CI_MERGE_REQUEST_DIFF_BASE_SHA', 'origin/master')
  end

  def run_git_command(*args)
    stdout, stderr, status = Open3.capture3('git', *args)

    unless status.success?
      warn "Warning: git #{args.first} failed: #{stderr.strip}" unless stderr.empty?
      return ''
    end

    stdout
  end

  def code_file?(file)
    return false unless file.end_with?('.rb')
    return false if file.start_with?('db/')
    return false if file.start_with?('spec/')
    return false if file.start_with?('ee/spec/')

    true
  end

  def extract_unique_by_from_diff(files)
    unique_bys = []

    files.each do |file|
      next unless File.exist?(file)

      diff = run_git_command('diff', "#{base_ref}...HEAD", '--', file)

      diff.each_line do |line|
        next unless line.start_with?('+') && !line.start_with?('+++')

        UNIQUE_BY_PATTERNS.each do |pattern|
          line.scan(pattern) do |match|
            columns = parse_columns(match[0])
            unique_bys << { file: file, columns: columns, line: line.strip }
          end
        end
      end
    end

    unique_bys
  end

  def extract_indexes_from_base_schema
    indexes = Set.new

    base_structure = run_git_command('show', "#{base_ref}:db/structure.sql")
    return indexes if base_structure.empty?

    STRUCTURE_SQL_PATTERNS.each do |pattern|
      base_structure.scan(pattern) do |match|
        columns_str = match.last
        columns = parse_sql_columns(columns_str)
        indexes << columns
      end
    end

    indexes
  end

  def extract_indexes_from_migrate_files
    indexes = Set.new

    migrate_files = changed_files.select { |f| f.start_with?('db/migrate/') && f.end_with?('.rb') }

    migrate_files.each do |file|
      next unless File.exist?(file)

      content = File.read(file)
      MIGRATE_INDEX_PATTERNS.each do |pattern|
        content.scan(pattern) do |match|
          indexes << parse_columns(match[0])
        end
      end
    end

    indexes
  end

  def parse_columns(match_str)
    match_str
      .gsub(/[:,]/, ' ')
      .split
      .map { |col| col.strip.delete_prefix(':') }
      .reject(&:empty?)
      .sort
  end

  def parse_sql_columns(columns_str)
    columns_str
      .split(',')
      .filter_map { |col| col.strip.split.first&.delete('"') }
      .reject(&:empty?)
      .sort
  end

  def check_violations(unique_bys, safe_indexes)
    unique_bys.each do |ub|
      next if safe_indexes.include?(ub[:columns])

      @errors << ub
    end
  end

  def print_errors
    puts "\e[31mERROR: unique_by declarations reference indexes not available at deploy time\e[0m"
    puts
    puts "This causes failures because:"
    puts "  - Post-deploy migrations run AFTER code deployment"
    puts "  - The index must exist BEFORE code using unique_by is deployed"
    puts
    puts "Violations found:"
    @errors.each do |error|
      puts "  #{error[:file]}"
      puts "    unique_by: [#{error[:columns].join(', ')}]"
      puts "    #{error[:line]}"
      puts
    end
    puts "Fix options:"
    puts "  1. Add the index in db/migrate/ instead of db/post_migrate/"
    puts "  2. Split into two MRs:"
    puts "     - MR1: Add index (merge and deploy first)"
    puts "     - MR2: Update code to use new unique_by (after index is deployed)"
    puts
    puts "See: INC-9604"
  end
end

exit UniqueByIndexChecker.new.run if $PROGRAM_NAME == __FILE__
