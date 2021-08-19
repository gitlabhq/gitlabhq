# frozen_string_literal: true

module Integrations
  class ProjectSerializer < BaseSerializer
    include WithPagination

    entity Integrations::ProjectEntity
  end
end
