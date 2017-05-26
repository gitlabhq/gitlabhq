<script>
  import eventHub from '../event_hub';

  export default {
    props: {
      canDestroy: {
        type: Boolean,
        required: true,
      },
      formState: {
        type: Object,
        required: true,
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
    },
    methods: {
      updateIssuable() {
        this.formState.updateLoading = true;
        eventHub.$emit('update.issuable');
      },
      closeForm() {
        eventHub.$emit('close.form');
      },
      deleteIssuable() {
        // eslint-disable-next-line no-alert
        if (confirm('Issue will be removed! Are you sure?')) {
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
      class="btn btn-save pull-left"
      :class="{ disabled: formState.updateLoading || !isSubmitEnabled }"
      type="submit"
      :disabled="updateLoading || !isSubmitEnabled"
      @click.prevent="updateIssuable">
      Save changes
      <i
        class="fa fa-spinner fa-spin"
        aria-hidden="true"
        v-if="formState.updateLoading">
      </i>
    </button>
    <button
      class="btn btn-default pull-right"
      type="button"
      @click="closeForm">
      Cancel
    </button>
    <button
      v-if="canDestroy"
      class="btn btn-danger pull-right append-right-default"
      :class="{ disabled: deleteLoading }"
      type="button"
      :disabled="deleteLoading"
      @click="deleteIssuable">
      Delete
      <i
        class="fa fa-spinner fa-spin"
        aria-hidden="true"
        v-if="deleteLoading">
      </i>
    </button>
  </div>
</template>
