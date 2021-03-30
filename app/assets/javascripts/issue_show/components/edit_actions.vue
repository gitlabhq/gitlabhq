<script>
import { GlButton } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import eventHub from '../event_hub';
import updateMixin from '../mixins/update';

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
    deleteIssuableButtonText() {
      return sprintf(__('Delete %{issuableType}'), {
        issuableType: issuableTypes[this.issuableType].toLowerCase(),
      });
    },
  },
  methods: {
    closeForm() {
      eventHub.$emit('close.form');
    },
    deleteIssuable() {
      const confirmMessage =
        this.issuableType === 'epic'
          ? __('Delete this epic and all descendants?')
          : sprintf(__('%{issuableType} will be removed! Are you sure?'), {
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
      variant="confirm"
      class="float-left qa-save-button gl-mr-3"
      type="submit"
      @click.prevent="updateIssuable"
    >
      {{ __('Save changes') }}
    </gl-button>
    <gl-button @click="closeForm">
      {{ __('Cancel') }}
    </gl-button>
    <gl-button
      v-if="shouldShowDeleteButton"
      :loading="deleteLoading"
      :disabled="deleteLoading"
      category="secondary"
      variant="danger"
      class="float-right qa-delete-button"
      @click="deleteIssuable"
    >
      {{ deleteIssuableButtonText }}
    </gl-button>
  </div>
</template>
