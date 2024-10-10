#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'application-settings-analysis'

class CiEnsureApplicationSettingsHaveDefinitionFile
  EXCEPTION = Class.new(StandardError)
  MISSING_DEFINITION_FILES = Class.new(EXCEPTION)
  EXTRA_DEFINITION_FILES = Class.new(EXCEPTION)

  def initialize(attributes:, definition_files:, stdout: $stdout, stderr: $stderr)
    @attributes = attributes
    @definition_files = definition_files
    @stdout = stdout
    @stderr = stderr
  end

  def execute!
    check_missing_definition_files!
    check_extra_definition_files!

    stdout.puts "All good! 🚀"
  end

  private

  attr_reader :attributes, :definition_files, :stdout, :stderr

  def check_missing_definition_files!
    as_missing_definition_file = attributes.reject(&:definition_file_exist?)
    return if as_missing_definition_file.empty?

    as_missing_definition_file.each do |as|
      stderr.puts "Attribute `#{as.attr}` is missing a definition file at `#{as.definition_file_path}`!"
    end

    raise MISSING_DEFINITION_FILES
  end

  def check_extra_definition_files!
    extra_definition_files = definition_files - attributes.map(&:definition_file_path)
    return if extra_definition_files.empty?

    extra_definition_files.each do |definition_file|
      stderr.puts "Definition file `#{definition_file.path}` doesn't have a corresponding attribute!"
    end

    raise EXTRA_DEFINITION_FILES
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    CiEnsureApplicationSettingsHaveDefinitionFile.new(
      attributes: ApplicationSettingsAnalysis.new.attributes,
      definition_files: ApplicationSettingsAnalysis.definition_files
    ).execute!
  rescue CiEnsureApplicationSettingsHaveDefinitionFile::EXCEPTION
    exit 1
  end
end
