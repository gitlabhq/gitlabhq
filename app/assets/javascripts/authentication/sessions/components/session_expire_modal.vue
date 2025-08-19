<script>
import { GlModal } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { refreshCurrentPage, visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { INTERVAL_SESSION_MODAL, BROADCAST_CHANNEL } from '../constants';

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
      broadcastChannel: null,
      intervalId: null,
      modalId: uniqueId('expire-session-modal-'),
      showModal: false,
      timeout: this.sessionTimeout,
    };
  },
  computed: {
    reload() {
      const text = this.signInUrl ? __('Sign in') : __('Reload page');
      return { text };
    },
  },
  async created() {
    this.broadcastChannel = new BroadcastChannel(BROADCAST_CHANNEL);
    this.broadcastChannel.postMessage(this.timeout);
    this.broadcastChannel.addEventListener('message', this.reset);
    this.setEvents();
  },
  beforeDestroy() {
    this.clearEvents();
    this.broadcastChannel.removeEventListener('message', this.reset);
    this.broadcastChannel.close();
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
      if (Date.now() >= this.timeout) {
        this.showModal = true;
        this.clearEvents();
      }
    },
    goTo() {
      if (this.signInUrl) {
        visitUrl(this.signInUrl);
      } else {
        refreshCurrentPage();
      }
    },
    onDocumentVisible() {
      if (document.visibilityState === 'visible') {
        this.checkStatus();
      }
    },
    /** @param {MessageEvent} event */
    reset(event) {
      this.timeout = event.data;
      if (!this.intervalId) {
        this.showModal = false;
        this.setEvents();
      }
    },
    setEvents() {
      this.intervalId = setInterval(this.checkStatus, INTERVAL_SESSION_MODAL);
      this.checkStatus();
      document.addEventListener('visibilitychange', this.onDocumentVisible);
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
