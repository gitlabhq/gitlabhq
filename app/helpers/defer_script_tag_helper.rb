# frozen_string_literal: true

module DeferScriptTagHelper
  # Override the default ActionView `javascript_include_tag` helper to support page specific deferred loading.
  # PLEASE NOTE: `defer` is also critical so that we don't run JavaScript entrypoints before the DOM is ready.
  # Please see https://gitlab.com/groups/gitlab-org/-/epics/4538#note_432159769.
  def javascript_include_tag(*sources)
    super(*sources, defer: true)
  end
end
