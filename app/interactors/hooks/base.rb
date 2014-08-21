module Hooks
  class Base < Interactor::Base
    def setup
      context.fail!(message: 'Invalid entity') if context[:entity].blank?
      context.fail!(message: 'Invalid event') if context[:event].blank?

      context[:event_data] = build_event_data(context[:entity], context[:event])
    end
  end
end
