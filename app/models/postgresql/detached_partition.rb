# frozen_string_literal: true

module Postgresql
  class DetachedPartition < ::Gitlab::Database::SharedModel
    scope :ready_to_drop, -> { where('drop_after < ?', Time.current) }
  end
end
