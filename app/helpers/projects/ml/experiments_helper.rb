# frozen_string_literal: true
module Projects
  module Ml
    module ExperimentsHelper
      require 'json'
      include ActionView::Helpers::NumberHelper

      def candidates_table_items(candidates)
        items = candidates.map do |candidate|
          {
            **candidate.params.to_h { |p| [p.name, p.value] },
            **candidate.latest_metrics.to_h { |m| [m.name, number_with_precision(m.value, precision: 4)] }
          }
        end

        Gitlab::Json.generate(items)
      end

      def unique_logged_names(candidates, &selector)
        Gitlab::Json.generate(candidates.flat_map(&selector).map(&:name).uniq)
      end
    end
  end
end
