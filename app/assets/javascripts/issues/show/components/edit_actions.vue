<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { __, sprintf } from '~/locale';
import Tracking from '~/tracking';
import eventHub from '../event_hub';
import updateMixin from '../mixins/update';
import getIssueStateQuery from '../queries/get_issue_state.query.graphql';
import DeleteIssueModal from './delete_issue_modal.vue';

const issuableTypes = {
  issue: __('Issue'),
  epic: __('Epic'),
  incident: __('Incident'),
};

const trackingMixin = Tracking.mixin({ label: 'delete_issue' });

export default {
  components: {
    DeleteIssueModal,
    GlButton,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [trackingMixin, updateMixin],
  props: {
    canDestroy: {
      type: Boolean,
      required: true,
    },
    endpoint: {
      required: true,
      type: String,
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
    isSubmitEnabled() {
      return this.formState.title.trim() !== '';
    },
    shouldShowDeleteButton() {
      return this.canDestroy && this.showDeleteButton && this.typeToShow;
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
      eventHub.$emit('delete.issuable');
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
        class="gl-mr-3"
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
        data-testid="issuable-delete-button"
        @click="track('click_button')"
      >
        {{ deleteIssuableButtonText }}
      </gl-button>
      <delete-issue-modal
        :issue-path="endpoint"
        :issue-type="typeToShow"
        :modal-id="modalId"
        :title="deleteIssuableButtonText"
        @delete="deleteIssuable"
      />
    </div>
  </div>
</template>
