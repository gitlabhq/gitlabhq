module Participable
  extend ActiveSupport::Concern

  module ClassMethods
    def participant(*attrs)
      participant_attrs.concat(attrs.map(&:to_s))
    end

    def participant_attrs
      @participant_attrs ||= []
    end
  end

  def participants(current_user = self.author)
    self.class.participant_attrs.flat_map do |attr|
      meth = method(attr)

      value = 
        if meth.arity == 1
          meth.call(current_user)
        else
          meth.call
        end

      participants_for(value, current_user)
    end.compact.uniq
  end

  private
    def participants_for(value, current_user = nil)
      case value
      when User
        [value]
      when Array
        value.flat_map { |v| participants_for(v, current_user) }
      when Participable
        value.participants(current_user)
      when Mentionable
        value.mentioned_users(current_user)
      end
    end
end
