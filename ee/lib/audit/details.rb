module Audit
  class Details
    ACTIONS = %i[add remove failed_login change custom_message].freeze

    def self.humanize(*args)
      new(*args).humanize
    end

    def initialize(details)
      @details = details
    end

    def humanize
      if @details[:with]
        "Signed in with #{@details[:with].upcase} authentication"
      else
        action_text
      end
    end

    private

    def action_text
      action = @details.slice(*ACTIONS)
      value = @details.values.first.tr('_', ' ')

      case action.keys.first
      when :add
        "Added #{value}#{@details[:as] ? " as #{@details[:as]}" : ''}"
      when :remove
        "Removed #{value}"
      when :failed_login
        "Failed to login with #{Gitlab::Auth::OAuth::Provider.label_for(value).upcase} authentication"
      when :custom_message
        value
      else
        text_for_change(value)
      end
    end

    def text_for_change(value)
      "Changed #{value}".tap do |changed_string|
        changed_string << " from #{@details[:from]}" if @details[:from]
        changed_string << " to #{@details[:to]}" if @details[:to]
      end
    end
  end
end
