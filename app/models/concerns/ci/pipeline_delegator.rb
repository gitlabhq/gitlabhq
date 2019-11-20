# frozen_string_literal: true

##
# This module is mainly used by child associations of `Ci::Pipeline` that needs to look up
# single source of truth. For example, `Ci::Build` has `git_ref` method, which behaves
# slightly different from `Ci::Pipeline`'s `git_ref`. This is very confusing as
# the system could behave differently time to time.
# We should have a single interface in `Ci::Pipeline` and access the method always.
module Ci
  module PipelineDelegator
    extend ActiveSupport::Concern

    included do
      delegate :merge_request_event?,
               :merge_request_ref?,
               :legacy_detached_merge_request_pipeline?,
               :merge_train_pipeline?, to: :pipeline
    end
  end
end
