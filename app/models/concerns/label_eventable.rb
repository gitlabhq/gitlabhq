# frozen_string_literal: true

# == LabelEventable concern
#
# Contains functionality related to objects that support adding/removing labels.
#
# This concern is not used yet, it will be used for:
# https://gitlab.com/gitlab-org/gitlab-foss/issues/48483

module LabelEventable
  extend ActiveSupport::Concern

  included do
    has_many :resource_label_events
  end
end
