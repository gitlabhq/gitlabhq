# frozen_string_literal: true

module FeatureGate
  def flipper_id
    return if new_record?

    "#{self.class.name}:#{id}"
  end
end
