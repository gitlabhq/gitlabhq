class GtOneCoercion < Virtus::Attribute
  def coerce(value)
    [1, value.to_i].max
  end
end
