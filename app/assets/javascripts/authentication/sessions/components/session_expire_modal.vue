<script>
import { GlModal } from '@gitlab/ui';
import { uniqueId } from 'lodash-es';
import { refreshCurrentPage, visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { BROADCAST_CHANNEL_SESSION_EXPIRE_MODAL_SHOWN, INTERVAL_SESSION_MODAL } from '../constants';

export default {
  name: 'SessionExpireModal',
  components: {
    GlModal,
  },
  props: {
    // When true, announce this modal's visibility on the shown-channel so subordinate
    // modals (the group-SAML reload modal) yield while it is shown and resume when it is
    // hidden. Only the general modal sets this.
    announceShown: {
      type: Boolean,
      required: false,
      default: false,
    },
    broadcastChannel: {
      type: String,
      required: true,
    },
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
      broadcastChannelInstance: null,
      shownChannelInstance: null,
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
    this.broadcastChannelInstance = new BroadcastChannel(this.broadcastChannel);
    this.broadcastChannelInstance.postMessage(this.timeout);
    this.broadcastChannelInstance.addEventListener('message', this.reset);
    if (this.announceShown) {
      this.shownChannelInstance = new BroadcastChannel(
        BROADCAST_CHANNEL_SESSION_EXPIRE_MODAL_SHOWN,
      );
    }
    this.setEvents();
  },
  beforeDestroy() {
    this.clearEvents();
    this.broadcastChannelInstance.removeEventListener('message', this.reset);
    this.broadcastChannelInstance.close();
    this.shownChannelInstance?.close();
  },
  methods: {
    clearEvents() {
      if (this.intervalId) {
        clearInterval(this.intervalId);
        document.removeEventListener('visibilitychange', this.onDocumentVisible);
        this.intervalId = null;
      }
    },
    announceShownState(shown) {
      this.shownChannelInstance?.postMessage(shown);
    },
    checkStatus() {
      if (Date.now() >= this.timeout) {
        this.showModal = true;
        this.announceShownState(true);
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
      // Ignore anything that isn't a deadline, so tabs running older code treat
      // future message types on this channel as a no-op.
      const deadline = Number(event.data);
      if (!Number.isFinite(deadline) || deadline <= 0) return;

      this.timeout = deadline;
      if (!this.intervalId) {
        // The modal had already fired; a later deadline hides it again, so tell the
        // subordinate modals they may resume (they yielded when it was shown).
        this.showModal = false;
        this.announceShownState(false);
        this.setEvents();
      }
    },
    setEvents() {
      // Poll rather than a single setTimeout to the deadline: background tabs throttle or
      // defer timers, so a one-shot timer can miss it. The interval plus the
      // visibilitychange re-check stays reliable.
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
