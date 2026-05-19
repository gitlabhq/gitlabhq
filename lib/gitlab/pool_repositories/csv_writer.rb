# frozen_string_literal: true

require 'csv'

module Gitlab
  module PoolRepositories
    class CsvWriter
      COLUMNS = [
        { key: :pool_id, header: 'Pool ID' },
        { key: :disk_path, header: 'Disk Path' },
        { key: :relative_path, header: 'Relative Path (Gitaly)' },
        { key: :source_project_id, header: 'Source Project ID' },
        { key: :state, header: 'State' },
        { key: :reason_codes, header: 'Reason Codes' },
        { key: :reasons, header: 'Reasons' },
        { key: :member_projects_count, header: 'Member Projects Count' },
        { key: :shard_name, header: 'Shard Name' }
      ].freeze

      CSV_HEADERS = COLUMNS.pluck(:header).freeze # rubocop:disable CodeReuse/ActiveRecord -- COLUMNS is a plain Ruby array, not ActiveRecord

      def initialize(output_file)
        @csv = CSV.open(output_file, 'w')
        @csv << CSV_HEADERS
      end

      def write_row(record)
        @csv << COLUMNS.map { |c| record[c[:key]] }
      end

      def close
        @csv&.close
        @csv = nil
      end
    end
  end
end
