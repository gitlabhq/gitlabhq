<script>
export default {
  props: {
    editPath: {
      type: String,
      required: true,
    },
    canCurrentUserFork: {
      type: Boolean,
      required: true,
    },
    canModifyBlob: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    handleEditClick(evt) {
      if (!this.canCurrentUserFork || this.canModifyBlob) {
        // if we can Edit, do default Edit button behavior
        return;
      }

      if (this.canCurrentUserFork) {
        evt.preventDefault();
        this.$emit('showForkMessage');
      }
    },
  },
};
</script>

<template>
  <a
    :href="editPath"
    class="btn btn-default js-edit-blob"
    @click="handleEditClick"
  >
    Edit
  </a>
</template>
