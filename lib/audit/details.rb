module Audit
  class Details
    ACTIONS = %i[add remove failed_login change].freeze
    
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
        "Failed to login with #{Gitlab::OAuth::Provider.label_for(value).upcase} authentication"
      else
        "Changed #{value} from #{@details[:from]} to #{@details[:to]}"
      end
    end
  end
end
