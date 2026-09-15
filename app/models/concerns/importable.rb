# frozen_string_literal: true

module Importable
  extend ActiveSupport::Concern

  attr_accessor :user_contributions, :importing
  alias_method :importing?, :importing
end
