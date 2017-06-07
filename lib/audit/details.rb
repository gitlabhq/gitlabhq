module Audit
  class Details
    CRUD_ACTIONS = %i[add remove change].freeze
    
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
        crud_action_text
      end
    end
    
    private
    
    def crud_action_text
      action = @details.slice(*CRUD_ACTIONS)
      value = @details.values.first.tr('_', ' ')
      
      case action.keys.first
      when :add
        "Added #{value}#{@details[:as] ? " as #{@details[:as]}" : ""}"
      when :remove
        "Removed #{value}"
      else
        "Changed #{value} from #{@details[:from]} to #{@details[:to]}"
      end
    end
  end
end
