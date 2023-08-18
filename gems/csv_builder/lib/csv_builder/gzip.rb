# frozen_string_literal: true

module CsvBuilder
  class Gzip < CsvBuilder::Builder
    # Writes the CSV file compressed and yields the written tempfile.
    #
    # Example:
    # > CsvBuilder::Gzip.new(Issue, { title: -> (row) { row.title.upcase }, id: :id }).render do |tempfile|
    # >   puts tempfile.path
    # >   puts `zcat #{tempfile.path}`
    # > end
    def render
      Tempfile.open(['csv_builder_gzip', '.csv.gz']) do |tempfile|
        csv = CSV.new(Zlib::GzipWriter.open(tempfile.path))

        write_csv csv, until_condition: -> {} # truncation must be handled outside of the CsvBuilder

        csv.close
        yield tempfile
      end
    end
  end
end
