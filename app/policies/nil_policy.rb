# frozen_string_literal: true

class NilPolicy < BasePolicy
  rule { default }.prevent_all
end
