# frozen_string_literal: true

module Gitlab
  module Database
    class PgDepend < SharedModel
      self.table_name = 'pg_depend'

      TYPES = {
        'VIEW' => %w[v m].freeze
      }.freeze

      scope :from_pg_extension, ->(type = nil) do
        joins('INNER JOIN pg_class ON pg_class.oid = pg_depend.objid')
          .where(pg_class: { relkind: TYPES.fetch(type.to_s) })
          .where("refclassid = 'pg_extension'::pg_catalog.regclass")
      end
    end
  end
end
