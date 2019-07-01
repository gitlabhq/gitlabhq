# frozen_string_literal: true

module Gitlab
  module Importers
    module CommonMetrics
    end
  end
end

Gitlab::Importers::CommonMetrics.prepend(EE::Gitlab::Importers::CommonMetrics)
