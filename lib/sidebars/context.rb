# frozen_string_literal: true

# This class stores all the information needed to display and
# render the sidebar and menus.
# It usually stores information regarding the context and calculated
# values where the logic is in helpers.
module Sidebars
  class Context
    attr_reader :current_user, :container

    def initialize(current_user:, container:, **args)
      @current_user = current_user
      @container = container

      args.each do |key, value|
        singleton_class.public_send(:attr_reader, key) # rubocop:disable GitlabSecurity/PublicSend
        instance_variable_set("@#{key}", value)
      end
    end
  end
end
