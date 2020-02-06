# frozen_string_literal: true

module Gitlab
  module Alerting
    class AlertAnnotation
      include ActiveModel::Model

      attr_accessor :label, :value
    end
  end
end
