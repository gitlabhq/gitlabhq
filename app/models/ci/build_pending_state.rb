# frozen_string_literal: true

class Ci::BuildPendingState < ApplicationRecord
  extend Gitlab::Ci::Model

  belongs_to :build, class_name: 'Ci::Build', foreign_key: :build_id

  validates :build, presence: true
end
