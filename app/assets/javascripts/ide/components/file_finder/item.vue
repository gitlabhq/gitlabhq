<script>
import FileIcon from '../../../vue_shared/components/file_icon.vue';

export default {
  components: {
    FileIcon,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <a
    href=""
    class="diff-changed-file"
  >
    <file-icon
      :file-name="file.name"
      :size="16"
      css-classes="diff-file-changed-icon append-right-8"
    />
    <span class="diff-changed-file-content append-right-8">
      <strong class="diff-changed-file-name">
        {{ file.name }}
      </strong>
      <span class="diff-changed-file-path prepend-top-5">
        {{ file.path }}
      </span>
    </span>
  </a>
</template>
