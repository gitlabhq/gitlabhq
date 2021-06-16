<script>
import { GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { __, sprintf } from '~/locale';
import eventHub from '../event_hub';
import updateMixin from '../mixins/update';
import getIssueStateQuery from '../queries/get_issue_state.query.graphql';

const issuableTypes = {
  issue: __('Issue'),
  epic: __('Epic'),
  incident: __('Incident'),
};

export default {
  components: {
    GlButton,
    GlModal,
  },
  directives: {
    GlModal: GlModalDirective,
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
      skipApollo: false,
      issueState: {},
      modalId: uniqueId('delete-issuable-modal-'),
    };
  },
  apollo: {
    issueState: {
      query: getIssueStateQuery,
      skip() {
        return this.skipApollo;
      },
      result() {
        this.skipApollo = true;
      },
    },
  },
  computed: {
    deleteIssuableButtonText() {
      return sprintf(__('Delete %{issuableType}'), {
        issuableType: this.typeToShow.toLowerCase(),
      });
    },
    deleteIssuableModalText() {
      return this.issuableType === 'epic'
        ? __('Delete this epic and all descendants?')
        : sprintf(__('%{issuableType} will be removed! Are you sure?'), {
            issuableType: this.typeToShow,
          });
    },
    isSubmitEnabled() {
      return this.formState.title.trim() !== '';
    },
    modalActionProps() {
      return {
        primary: {
          text: this.deleteIssuableButtonText,
          attributes: [{ variant: 'danger' }, { loading: this.deleteLoading }],
        },
        cancel: {
          text: __('Cancel'),
        },
      };
    },
    shouldShowDeleteButton() {
      return this.canDestroy && this.showDeleteButton;
    },
    typeToShow() {
      const { issueState, issuableType } = this;
      const type = issueState.issueType ?? issuableType;
      return issuableTypes[type];
    },
  },
  methods: {
    closeForm() {
      eventHub.$emit('close.form');
    },
    deleteIssuable() {
      this.deleteLoading = true;
      eventHub.$emit('delete.issuable', { destroy_confirm: true });
    },
  },
};
</script>

<template>
  <div class="gl-mt-3 gl-mb-3 gl-display-flex gl-justify-content-space-between">
    <div>
      <gl-button
        :loading="formState.updateLoading"
        :disabled="formState.updateLoading || !isSubmitEnabled"
        category="primary"
        variant="confirm"
        class="qa-save-button gl-mr-3"
        data-testid="issuable-save-button"
        type="submit"
        @click.prevent="updateIssuable"
      >
        {{ __('Save changes') }}
      </gl-button>
      <gl-button data-testid="issuable-cancel-button" @click="closeForm">
        {{ __('Cancel') }}
      </gl-button>
    </div>
    <div v-if="shouldShowDeleteButton">
      <gl-button
        v-gl-modal="modalId"
        :loading="deleteLoading"
        :disabled="deleteLoading"
        category="secondary"
        variant="danger"
        class="qa-delete-button"
        data-testid="issuable-delete-button"
      >
        {{ deleteIssuableButtonText }}
      </gl-button>
      <gl-modal
        ref="removeModal"
        :modal-id="modalId"
        size="sm"
        :action-primary="modalActionProps.primary"
        :action-cancel="modalActionProps.cancel"
        @primary="deleteIssuable"
      >
        <template #modal-title>{{ deleteIssuableButtonText }}</template>
        <div>
          <p class="gl-mb-1">{{ deleteIssuableModalText }}</p>
        </div>
      </gl-modal>
    </div>
  </div>
</template>
