<script>
  import updateMixin from '../mixins/update';
  import eventHub from '../event_hub';

  export default {
    mixins: [updateMixin],
    props: {
      canDestroy: {
        type: Boolean,
        required: true,
      },
      formState: {
        type: Object,
        required: true,
      },
      showDeleteButton: {
        type: Boolean,
        required: false,
        default: true,
      },
    },
    data() {
      return {
        deleteLoading: false,
      };
    },
    computed: {
      isSubmitEnabled() {
        return this.formState.title.trim() !== '';
      },
      shouldShowDeleteButton() {
        return this.canDestroy && this.showDeleteButton;
      },
    },
    methods: {
      closeForm() {
        eventHub.$emit('close.form');
      },
      deleteIssuable() {
        // eslint-disable-next-line no-alert
        if (window.confirm('Issue will be removed! Are you sure?')) {
          this.deleteLoading = true;

          eventHub.$emit('delete.issuable');
        }
      },
    },
  };
</script>

<template>
  <div class="prepend-top-default append-bottom-default clearfix">
    <button
      :class="{ disabled: formState.updateLoading || !isSubmitEnabled }"
      :disabled="formState.updateLoading || !isSubmitEnabled"
      class="btn btn-save float-left"
      type="submit"
      @click.prevent="updateIssuable">
      Save changes
      <i
        v-if="formState.updateLoading"
        class="fa fa-spinner fa-spin"
        aria-hidden="true">
      </i>
    </button>
    <button
      class="btn btn-default float-right"
      type="button"
      @click="closeForm">
      Cancel
    </button>
    <button
      v-if="shouldShowDeleteButton"
      :class="{ disabled: deleteLoading }"
      :disabled="deleteLoading"
      class="btn btn-danger float-right append-right-default"
      type="button"
      @click="deleteIssuable">
      Delete
      <i
        v-if="deleteLoading"
        class="fa fa-spinner fa-spin"
        aria-hidden="true">
      </i>
    </button>
  </div>
</template>
