# frozen_string_literal: true

# Extend `disable_joins` to accept Proc
ActiveRecord::Associations::Association.prepend(GemExtensions::ActiveRecord::ConfigurableDisableJoins)
