# frozen_string_literal: true

module Postgresql
  class DetachedPartition < ApplicationRecord
    scope :ready_to_drop, -> { where('drop_after < ?', Time.current) }
  end
end
