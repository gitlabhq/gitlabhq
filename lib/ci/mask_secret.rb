module Ci::MaskSecret
  class << self
    def mask(value, token)
      return value unless value.present? && token.present?

      value.gsub(token, 'x' * token.length)
    end
  end
end
