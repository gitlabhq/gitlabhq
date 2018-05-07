<script>
export default {
  props: {
    editPath: {
      type: String,
      required: false,
      default: '',
    },
    currentUser: {
      type: Boolean,
      required: false,
      default: false,
    },
    canCreateMergeReqest: {
      type: Boolean,
      required: false,
      default: false,
    },
    canFork: {
      type: Boolean,
      required: false,
      default: false,
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

      if (this.canFork && this.canCreateMergeRequest) {
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
