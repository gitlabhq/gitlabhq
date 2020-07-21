<script>
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import Tracking from '~/tracking';
import { TrackingLabels } from '../constants';

export default {
  name: 'CodeInstruction',
  components: {
    ClipboardButton,
  },
  mixins: [
    Tracking.mixin({
      label: TrackingLabels.CODE_INSTRUCTION,
    }),
  ],
  props: {
    instruction: {
      type: String,
      required: true,
    },
    copyText: {
      type: String,
      required: true,
    },
    multiline: {
      type: Boolean,
      required: false,
      default: false,
    },
    trackingAction: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    trackCopy() {
      if (this.trackingAction) {
        this.track(this.trackingAction);
      }
    },
  },
};
</script>

<template>
  <div v-if="!multiline" class="input-group append-bottom-10">
    <input
      :value="instruction"
      type="text"
      class="form-control monospace js-instruction-input"
      readonly
      @copy="trackCopy"
    />
    <span class="input-group-append js-instruction-button" @click="trackCopy">
      <clipboard-button :text="instruction" :title="copyText" class="input-group-text" />
    </span>
  </div>

  <div v-else>
    <pre class="js-instruction-pre" @copy="trackCopy">{{ instruction }}</pre>
  </div>
</template>
