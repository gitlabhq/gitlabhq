class Vulnerabilities::OccurrenceSerializer < BaseSerializer
  include WithPagination

  entity Vulnerabilities::OccurrenceEntity
end
