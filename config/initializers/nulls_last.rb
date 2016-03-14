module ActiveRecord
  class Base
    def self.nulls_last(field, direction = 'ASC')
      if Gitlab::Database.postgresql?
        "#{field} #{direction} NULLS LAST"
      else
        if direction.upcase == 'ASC'
          "-#{field} DESC"
        else
          "#{field} DESC"
        end
      end
    end
  end
end
