<script>
export default {
  props: {
    editPath: {
      type: String,
      required: true,
    },
    currentUser: {
      type: Object,
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
      if (!this.currentUser || this.canModifyBlob) {
        // if we can Edit, do default Edit button behavior
        return;
      }

      if (this.currentUser.canFork && this.currentUser.canCreateMergeRequest) {
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
