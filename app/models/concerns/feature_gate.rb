module FeatureGate
  def flipper_id
    return nil if new_record?

    "#{self.class.name}:#{id}"
  end
end
