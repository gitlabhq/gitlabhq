# frozen_string_literal: true

# == LabelEventable concern
#
# Contains functionality related to objects that support adding/removing labels.
#

module LabelEventable
  extend ActiveSupport::Concern

  included do
    has_many :resource_label_events
  end
end
