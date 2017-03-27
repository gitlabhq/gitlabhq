module Importable
  extend ActiveSupport::Concern

  attr_accessor :importing
  alias_method :importing?, :importing

  attr_accessor :skip_metrics
  alias_method :skip_metrics?, :skip_metrics
end
