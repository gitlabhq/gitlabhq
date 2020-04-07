# frozen_string_literal: true
module Metrics
  module Dashboard
    class AnnotationPolicy < BasePolicy
      delegate { @subject.cluster }
      delegate { @subject.environment }
    end
  end
end
