<script>
import WebIdeLink from '~/vue_shared/components/web_ide_link.vue';

export default {
  components: {
    WebIdeLink,
  },
  props: {
    showEditButton: {
      type: Boolean,
      required: true,
    },
    editPath: {
      type: String,
      required: true,
    },
    webIdePath: {
      type: String,
      required: true,
    },
    needsToFork: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    onEdit(target) {
      this.$emit('edit', target);
    },
  },
};
</script>

<template>
  <web-ide-link
    :show-edit-button="showEditButton"
    class="gl-mr-3"
    :edit-url="editPath"
    :web-ide-url="webIdePath"
    :needs-to-fork="needsToFork"
    :is-blob="true"
    disable-fork-modal
    @edit="onEdit"
  />
</template>
