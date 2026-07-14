<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  name: 'MirrorActions',
  components: {
    GlButton,
    ClipboardButton,
  },
  props: {
    mirror: {
      type: Object,
      required: true,
    },
  },
  emits: ['sync', 'toggle', 'delete'],
  computed: {
    isPullMirror() {
      return this.mirror.direction === 'pull';
    },
    isUpdating() {
      return this.mirror.updateStatus === 'started';
    },
    showSyncButton() {
      return this.mirror.enabled || this.isUpdating;
    },
    syncButtonDisabled() {
      return this.isUpdating;
    },
    syncButtonTitle() {
      if (this.isUpdating) return this.$options.i18n.updating;
      return this.$options.i18n.updateNow;
    },
    syncButtonIconClasses() {
      return this.isUpdating ? 'spin' : '';
    },
    showToggleButton() {
      return !this.isPullMirror;
    },
  },
  i18n: {
    copySSHPublicKey: s__('Mirror|Copy SSH public key'),
    updateNow: s__('Mirror|Update now'),
    updating: s__('Mirror|Updating'),
    disable: s__('Mirror|Disable'),
    enable: s__('Mirror|Enable'),
    remove: s__('Mirror|Remove'),
  },
};
</script>

<template>
  <div class="gl-flex gl-justify-end gl-gap-2">
    <clipboard-button
      v-if="mirror.sshKeyAuth && mirror.sshPublicKey"
      :text="mirror.sshPublicKey"
      :title="$options.i18n.copySSHPublicKey"
      :aria-label="$options.i18n.copySSHPublicKey"
      data-testid="copy-public-key-button"
    />
    <gl-button
      v-if="showSyncButton"
      icon="retry"
      :disabled="syncButtonDisabled"
      :aria-label="syncButtonTitle"
      :icon-classes="syncButtonIconClasses"
      data-testid="update-now-button"
      @click="$emit('sync', { id: mirror.id, direction: mirror.direction })"
    />
    <gl-button
      v-if="showToggleButton && mirror.enabled"
      icon="stop"
      :aria-label="$options.i18n.disable"
      data-testid="disable-mirror-button"
      @click="$emit('toggle', { id: mirror.id, direction: mirror.direction })"
    />
    <gl-button
      v-if="showToggleButton && !mirror.enabled"
      icon="play"
      :aria-label="$options.i18n.enable"
      data-testid="enable-mirror-button"
      @click="$emit('toggle', { id: mirror.id, direction: mirror.direction })"
    />
    <gl-button
      variant="danger"
      category="secondary"
      icon="remove"
      :aria-label="$options.i18n.remove"
      data-testid="delete-mirror-button"
      @click="$emit('delete', { id: mirror.id, direction: mirror.direction })"
    />
  </div>
</template>
