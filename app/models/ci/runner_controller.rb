# frozen_string_literal: true

module Ci
  class RunnerController < Ci::ApplicationRecord
    validates :description, length: { maximum: 1024 }

    has_many :tokens,
      class_name: 'Ci::RunnerControllerToken',
      inverse_of: :runner_controller
  end
end
