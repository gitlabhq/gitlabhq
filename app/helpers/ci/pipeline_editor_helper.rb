# frozen_string_literal: true

module Ci
  module PipelineEditorHelper
    include ChecksCollaboration

    def can_view_pipeline_editor?(project)
      can_collaborate_with_project?(project) &&
        Gitlab::Ci::Features.ci_pipeline_editor_page_enabled?(project)
    end
  end
end
