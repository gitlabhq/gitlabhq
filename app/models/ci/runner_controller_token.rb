# frozen_string_literal: true

module Ci
  class RunnerControllerToken < Ci::ApplicationRecord
    belongs_to :runner_controller,
      class_name: 'Ci::RunnerController',
      inverse_of: :tokens

    validates :token_digest, presence: true, length: { maximum: 255 }, uniqueness: true
    validates :description, length: { maximum: 1024 }
  end
end
