# frozen_string_literal: true

module Ci
  class TestCaseFailure < ApplicationRecord
    extend Gitlab::Ci::Model

    validates :test_case, :build, :failed_at, presence: true

    belongs_to :test_case, class_name: "Ci::TestCase", foreign_key: :test_case_id
    belongs_to :build, class_name: "Ci::Build", foreign_key: :build_id
  end
end
