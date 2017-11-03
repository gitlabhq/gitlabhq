module EE
  module AuditEvent
    extend ActiveSupport::Concern

    def author_name
      details[:author_name].blank? ? user&.name : details[:author_name]
    end

    def entity
      return unless entity_type && entity_id

      # Avoiding exception if the record doesn't exist
      @entity ||= entity_type.constantize.find_by_id(entity_id)
    end

    def present
      AuditEventPresenter.new(self)
    end
  end
end
