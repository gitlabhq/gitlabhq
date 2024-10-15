# frozen_string_literal: true

module Ci
  class JobSerializer < BaseSerializer
    entity Ci::JobEntity

    def represent(resource, opts = {}, entity_class = nil)
      super(resource, opts, entity_class || self.class.entity_class)
    end
  end
end
