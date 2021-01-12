# frozen_string_literal: true

module ReleaseHighlights
  class Validator
    attr_reader :errors, :file

    def initialize(file:)
      @file = file
      @errors = []
    end

    def valid?
      document = YAML.parse(File.read(file))

      document.root.children.each do |entry|
        entry = ReleaseHighlights::Validator::Entry.new(entry)

        errors.push(entry.errors.full_messages) unless entry.valid?
      end

      errors.none?
    end

    def self.validate_all!
      @all_errors = []

      ReleaseHighlight.file_paths.each do |file_path|
        instance = self.new(file: file_path)

        @all_errors.push([instance.errors, instance.file]) unless instance.valid?
      end

      @all_errors.none?
    end

    def self.error_message
      io = StringIO.new

      @all_errors.each do |errors, file|
        message = "Validation failed for #{file}"
        line = -> { io.puts "-" * message.length }

        line.call
        io.puts message
        line.call

        errors.flatten.each { |error| io.puts "* #{error}" }
        io.puts
      end

      io.string
    end
  end
end
