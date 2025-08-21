#!/usr/bin/env ruby
# frozen_string_literal: true

# Splits large Cobertura XML files into smaller chunks for GitLab's 10MB limit
# Usage: ruby scripts/cobertura_splitter.rb coverage/coverage.xml

require 'nokogiri'

class CoberturaSplitter
  def initialize(input_file)
    @input_file = input_file
    @doc = Nokogiri::XML(File.read(input_file))
  end

  def split(max_size_mb: 9)
    packages = @doc.xpath('//package')
    max_size_bytes = max_size_mb * 1024 * 1024

    package_groups = []
    current_group = []

    packages.each do |package|
      # Test what the file size would be if we add this package
      test_group = current_group + [package]
      test_xml = create_xml_builder(test_group).to_xml

      # If adding this package would exceed the limit, start new group
      if test_xml.bytesize > max_size_bytes
        package_groups << current_group unless current_group.empty?

        current_group = [package]
      else
        current_group << package
      end
    end

    # Add the last group
    package_groups << current_group unless current_group.empty?

    base_dir = File.dirname(@input_file)
    package_groups.map.with_index do |group, index|
      output_file = File.join(base_dir, "coverage-#{index}.xml")

      builder = create_xml_builder(group)
      File.write(output_file, builder.to_xml)

      file_size = (File.size(output_file) / 1024.0 / 1024.0).round(1)
      {
        path: output_file,
        size_mb: file_size,
        package_count: group.size
      }
    end
  end

  def display_results(output_files)
    puts "Found packages, created #{output_files.size} files:"
    output_files.each do |file_info|
      puts "  #{File.basename(file_info[:path])}: #{file_info[:size_mb]}MB (#{file_info[:package_count]} packages)"
    end
  end

  private

  def create_xml_builder(package_chunk)
    lines_covered, lines_valid = calculate_totals(package_chunk)
    line_rate = lines_valid > 0 ? (lines_covered.to_f / lines_valid).round(2) : 0.0

    Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.doc.create_internal_subset('coverage', nil, 'http://cobertura.sourceforge.net/xml/coverage-04.dtd')

      original_attrs = @doc.root.attributes.transform_values(&:value)
      attrs = original_attrs.merge(
        'lines-covered' => lines_covered.to_s,
        'lines-valid' => lines_valid.to_s,
        'line-rate' => line_rate.to_s
      )

      xml.coverage(attrs) do
        xml.sources do
          @doc.xpath('//source').each { |source| xml.source source.text }
        end
        xml.packages do
          package_chunk.each { |package| xml << package.to_xml }
        end
      end
    end
  end

  def calculate_totals(packages)
    lines_covered = 0
    lines_valid = 0

    packages.each do |package|
      package.xpath('.//line').each do |line|
        hits = line['hits'].to_i
        lines_valid += 1
        lines_covered += 1 if hits > 0
      end
    end

    [lines_covered, lines_valid]
  end
end

if __FILE__ == $PROGRAM_NAME
  input_file = ARGV[0]

  unless input_file && File.exist?(input_file)
    puts "Usage: ruby scripts/cobertura_splitter.rb <coverage.xml>"
    exit 1
  end

  splitter = CoberturaSplitter.new(input_file)
  output_files = splitter.split
  splitter.display_results(output_files)
end
