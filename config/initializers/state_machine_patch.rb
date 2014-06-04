# This is a patch to address the issue in https://github.com/pluginaweek/state_machine/issues/251
# where gem 'state_machine' was not working for Rails 4.1
module StateMachine
  module Integrations
    module ActiveModel
      public :around_validation
    end
  end
end
