module Importable
  extend ActiveSupport::Concern

  attr_accessor :importing
  alias_method :importing?, :importing
end
