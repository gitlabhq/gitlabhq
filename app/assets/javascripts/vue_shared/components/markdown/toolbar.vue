<script>
  export default {
    props: {
      markdownDocs: {
        type: String,
        required: true,
      },
    },
  };
</script>

<template>
  <div class="comment-toolbar clearfix">
    <div class="toolbar-text">
      <a
        :href="markdownDocs"
        target="_blank"
        tabindex="-1">
        Markdown is supported
      </a>
    </div>
    <button
      class="toolbar-button markdown-selector"
      type="button"
      tabindex="-1">
      <i
        class="fa fa-file-image-o toolbar-button-icon"
        aria-hidden="true">
      </i>
      Attach a file
    </button>
  </div>
</template>
