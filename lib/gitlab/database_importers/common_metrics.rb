# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module CommonMetrics
    end
  end
end

Gitlab::DatabaseImporters::CommonMetrics.prepend_if_ee('EE::Gitlab::DatabaseImporters::CommonMetrics')
