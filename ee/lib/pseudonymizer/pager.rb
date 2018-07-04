module Pseudonymizer
  class Pager
    PAGE_SIZE = ENV.fetch('PSEUDONYMIZER_BATCH', 100_000)

    def initialize(table, columns)
      @table = table
      @columns = columns
    end

    def pages(&block)
      if @columns.include?("id")
        # optimize the pagination using WHERE id > ?
        pages_per_id(&block)
      else
        # fallback to `LIMIT ? OFFSET ?` when "id" is unavailable
        pages_per_offset(&block)
      end
    end

    def pages_per_id(&block)
      id_offset = 0

      loop do
        # a page of results
        results = ActiveRecord::Base.connection.exec_query(<<-SQL.squish)
          SELECT #{@columns.join(",")}
          FROM #{@table}
          WHERE id > #{id_offset}
          ORDER BY id
          LIMIT #{PAGE_SIZE}
        SQL
        Rails.logger.debug("#{self.class.name} fetch ids [#{id_offset}..+#{PAGE_SIZE}]")
        break if results.empty?

        id_offset = results.last["id"].to_i
        yield results

        break if results.count < PAGE_SIZE
      end
    end

    def pages_per_offset(&block)
      offset = 0

      loop do
        # a page of results
        results = ActiveRecord::Base.connection.exec_query(<<-SQL.squish)
          SELECT #{@columns.join(",")}
          FROM #{@table}
          ORDER BY #{@columns.join(",")}
          LIMIT #{PAGE_SIZE} OFFSET #{offset}
        SQL
        Rails.logger.debug("#{self.class.name} fetching offset [#{offset}..#{offset + PAGE_SIZE}]")
        break if results.empty?

        offset += PAGE_SIZE
        yield results

        break if results.count < PAGE_SIZE
      end
    end
  end
end
