class FillPagesDomainVerificationCode < ActiveRecord::Migration
  DOWNTIME = false

  class PagesDomain < ActiveRecord::Base
    include EachBatch
  end

  # Allow this migration to resume if it fails partway through
  disable_ddl_transaction!

  def up
    PagesDomain.where(verification_code: [nil, '']).each_batch do |relation|
      connection.execute(set_codes_sql(relation))

      # Sleep 2 minutes between batches to not overload the DB with dead tuples
      sleep(2.minutes) unless relation.reorder(:id).last == PagesDomain.reorder(:id).last
    end

    change_column_null(:pages_domains, :verification_code, false)
  end

  def down
    change_column_null(:pages_domains, :verification_code, true)
  end

  private

  def set_codes_sql(relation)
    ids = relation.pluck(:id)
    whens = ids.map { |id| "WHEN #{id} THEN '#{SecureRandom.hex(16)}'" }

    <<~SQL
      UPDATE pages_domains
      SET verification_code =
        CASE id
        #{whens.join("\n")}
        END
      WHERE id IN(#{ids.join(',')})
    SQL
  end
end
