# == LabelEventable concern
#
# Contains functionality related to objects that support adding/removing events.
#
# Used by Issue and MergeRequest.
#

module LabelEventable
  extend ActiveSupport::Concern

  included do
    has_many :resource_label_events
  end
end
