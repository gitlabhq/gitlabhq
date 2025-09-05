# frozen_string_literal: true

module SupplyChain
  module Slsa
    class ResourceDescriptor
      include ActiveModel::Model

      attr_accessor :name, :digest, :uri
    end
  end
end
