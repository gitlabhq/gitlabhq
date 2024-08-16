<script>
import { GlButton } from '@gitlab/ui';
import Tracking from '~/tracking';
import eventHub from '../event_hub';
import updateMixin from '../mixins/update';
import getIssueStateQuery from '../queries/get_issue_state.query.graphql';

const trackingMixin = Tracking.mixin({ label: 'delete_issue' });

export default {
  components: {
    GlButton,
  },
  mixins: [trackingMixin, updateMixin],
  props: {
    endpoint: {
      required: true,
      type: String,
    },
    formState: {
      type: Object,
      required: true,
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
    isSubmitEnabled() {
      return this.formState.title.trim() !== '';
    },
  },
  methods: {
    closeForm() {
      eventHub.$emit('close.form');
    },
  },
};
</script>

<template>
  <div class="gl-mb-3 gl-mt-3 gl-flex">
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
</template>
