# frozen_string_literal: true

module SignatureType
  TYPES = %i[gpg ssh x509].freeze

  def type
    raise NoMethodError, 'must implement `type` method'
  end

  TYPES.each do |type|
    define_method("#{type}?") { self.type == type }
  end
end
