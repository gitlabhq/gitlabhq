<script>
export default {
  props: {
    total: {
      type: String,
      required: true,
    },
    visible: {
      type: Number,
      required: true,
    },
  },
};
</script>

<template>
  <div class="alert alert-warning">
    <h4>
      {{ __('Too many changes to show.') }}
    </h4>
    <div class="pull-right">
<!-- TODO: psimyn
- if current_controller?(:commit)
= link_to "Plain diff", project_commit_path(@project, @commit, format: :diff), class: "btn btn-sm"
= link_to "Email patch", project_commit_path(@project, @commit, format: :patch), class: "btn btn-sm"
- elsif current_controller?('projects/merge_requests/diffs') && @merge_request&.persisted?
= link_to "Plain diff", merge_request_path(@merge_request, format: :diff), class: "btn btn-sm"
= link_to "Email patch", merge_request_path(@merge_request, format: :patch), class: "btn btn-sm"
-->
    </div>
    <p>
      To preserve performance only
      <strong>
        {{ visible }} of {{ total }}
      </strong>
      files are displayed.
    </p>
  </div>
</template>
