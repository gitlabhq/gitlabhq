# frozen_string_literal: true

# SnoozingService class
#
# Used for snoozing/un-snoozing todos
#
# Ex.
#   SnoozingService.new.snooze(todo, 1.day.from_now)
#
module Todos
  class SnoozingService
    def snooze_todo(todo, snooze_until)
      if !todo.snoozed_until.nil? || todo.update(snoozed_until: snooze_until)
        ServiceResponse.success(payload: { todo: todo })
      else
        ServiceResponse.error(message: todo.errors.full_messages)
      end
    end

    def un_snooze_todo(todo)
      if todo.snoozed_until.nil? || todo.update(snoozed_until: nil)
        ServiceResponse.success(payload: { todo: todo })
      else
        ServiceResponse.error(message: todo.errors.full_messages)
      end
    end
  end
end
