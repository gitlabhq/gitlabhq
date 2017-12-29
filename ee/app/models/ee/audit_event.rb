module EE
  module AuditEvent
    extend ActiveSupport::Concern

    def author_name
      details[:author_name].presence || user&.name
    end

    def entity
      return unless entity_type && entity_id

      # Avoiding exception if the record doesn't exist
      @entity ||= entity_type.constantize.find_by_id(entity_id) # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end

    def present
      AuditEventPresenter.new(self)
    end
  end
end
