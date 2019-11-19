# frozen_string_literal: true

class DeploymentMergeRequest < ApplicationRecord
  belongs_to :deployment, optional: false
  belongs_to :merge_request, optional: false
end
