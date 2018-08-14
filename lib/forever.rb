class Forever
  POSTGRESQL_DATE = DateTime.new(3000, 1, 1)
  MYSQL_DATE = DateTime.new(2038, 01, 19)

  # MySQL timestamp has a range of '1970-01-01 00:00:01' UTC to '2038-01-19 03:14:07' UTC
  def self.date
    if Gitlab::Database.postgresql?
      POSTGRESQL_DATE
    else
      MYSQL_DATE
    end
  end
end
