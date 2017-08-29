<script>
export default {
  name: 'repo-file-footer',
  props: {
    filePath: {
      type: String,
      required: true,
    },
    mimeType: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="repo-file-footer">
    <i
      aria-label="branch"
      class="fa fa-code-fork"
    />
    <span>{{filePath}}</span>
    <span class="pull-right">{{mimeType}}</span>
  </div>
</template>
