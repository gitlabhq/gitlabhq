# frozen_string_literal: true

module Authn
  module IamReplication
    def self.enabled?
      Feature.enabled?(:iam_data_replication, :instance)
    end
  end
end
