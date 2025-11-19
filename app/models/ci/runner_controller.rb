# frozen_string_literal: true

module Ci
  class RunnerController < Ci::ApplicationRecord
    validates :description, length: { maximum: 1024 }
  end
end
