<script>
import { GlAlert } from '@gitlab/ui';
import { slugifyWithUnderscore } from '~/lib/utils/text_utility';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

export default {
  components: {
    GlAlert,
    LocalStorageSync,
  },
  props: {
    featureName: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isDismissed: false,
    };
  },
  computed: {
    storageKey() {
      return `${slugifyWithUnderscore(this.featureName)}_feedback_dismissed`;
    },
    showAlert() {
      return !this.isDismissed;
    },
  },
  methods: {
    dismissFeedbackAlert() {
      this.isDismissed = true;
    },
  },
};
</script>

<template>
  <div v-show="showAlert">
    <local-storage-sync v-model="isDismissed" :storage-key="storageKey" />
    <gl-alert v-if="showAlert" v-bind="$attrs" @dismiss="dismissFeedbackAlert">
      <slot></slot>
    </gl-alert>
  </div>
</template>
