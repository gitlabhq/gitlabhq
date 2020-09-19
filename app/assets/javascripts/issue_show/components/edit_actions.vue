<script>
import { GlButton } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import updateMixin from '../mixins/update';
import eventHub from '../event_hub';

const issuableTypes = {
  issue: __('Issue'),
  epic: __('Epic'),
};

export default {
  components: {
    GlButton,
  },
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
    issuableType: {
      type: String,
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
    shouldShowDeleteButton() {
      return this.canDestroy && this.showDeleteButton;
    },
  },
  methods: {
    closeForm() {
      eventHub.$emit('close.form');
    },
    deleteIssuable() {
      const confirmMessage = sprintf(__('%{issuableType} will be removed! Are you sure?'), {
        issuableType: issuableTypes[this.issuableType],
      });
      // eslint-disable-next-line no-alert
      if (window.confirm(confirmMessage)) {
        this.deleteLoading = true;

        eventHub.$emit('delete.issuable', { destroy_confirm: true });
      }
    },
  },
};
</script>

<template>
  <div class="gl-mt-3 gl-mb-3 clearfix">
    <gl-button
      :loading="formState.updateLoading"
      :disabled="formState.updateLoading || !isSubmitEnabled"
      category="primary"
      variant="success"
      class="float-left qa-save-button"
      type="submit"
      @click.prevent="updateIssuable"
    >
      {{ __('Save changes') }}
    </gl-button>
    <gl-button class="float-right" @click="closeForm">
      {{ __('Cancel') }}
    </gl-button>
    <gl-button
      v-if="shouldShowDeleteButton"
      :loading="deleteLoading"
      :disabled="deleteLoading"
      category="primary"
      variant="danger"
      class="float-right gl-mr-3 qa-delete-button"
      @click="deleteIssuable"
    >
      {{ __('Delete') }}
    </gl-button>
  </div>
</template>
