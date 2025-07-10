<script>
import { GlModal } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { refreshCurrentPage, visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { INTERVAL_SESSION_MODAL } from '../constants';

export default {
  components: {
    GlModal,
  },
  props: {
    message: {
      type: String,
      required: true,
    },
    sessionTimeout: {
      type: Number,
      required: true,
    },
    signInUrl: {
      type: String,
      default: null,
      required: false,
    },
    title: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      intervalId: null,
      modalId: uniqueId('expire-session-modal-'),
      showModal: false,
    };
  },
  computed: {
    reload() {
      const text = this.signInUrl ? __('Sign in') : __('Reload page');
      return { text };
    },
  },
  async created() {
    this.intervalId = setInterval(this.checkStatus, INTERVAL_SESSION_MODAL);
    document.addEventListener('visibilitychange', this.onDocumentVisible);
  },
  beforeDestroy() {
    this.clearEvents();
  },
  methods: {
    clearEvents() {
      if (this.intervalId) {
        clearInterval(this.intervalId);
        document.removeEventListener('visibilitychange', this.onDocumentVisible);
        this.intervalId = null;
      }
    },
    checkStatus() {
      if (Date.now() >= this.sessionTimeout) {
        this.showModal = true;
        this.clearEvents();
      }
    },
    onDocumentVisible() {
      if (document.visibilityState === 'visible') {
        this.checkStatus();
      }
    },
    goTo() {
      if (this.signInUrl) {
        visitUrl(this.signInUrl);
      } else {
        refreshCurrentPage();
      }
    },
  },
  cancel: { text: __('Cancel') },
};
</script>

<template>
  <gl-modal
    v-model="showModal"
    :modal-id="modalId"
    :title="title"
    :action-primary="reload"
    :action-cancel="$options.cancel"
    aria-live="assertive"
    @primary="goTo"
  >
    {{ message }}
  </gl-modal>
</template>
