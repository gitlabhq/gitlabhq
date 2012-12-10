# Contains search method as workaround for Postgresql
# Override accessor for "has_many :notes"
# Workaround for PostgreSQL: using integer ids on (text column) noteable_id in WHERE clause produces error
# see https://github.com/gitlabhq/gitlabhq/issues/1957
module Noteable
  extend ActiveSupport::Concern

  included do
    def notes
      Note.where(noteable_id: id.to_s, noteable_type: self.class.name)
    end
  end
end