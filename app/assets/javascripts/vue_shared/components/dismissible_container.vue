<script>
import { GlIcon } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';

export default {
  components: {
    GlIcon,
  },
  props: {
    path: {
      type: String,
      required: true,
    },
    featureId: {
      type: String,
      required: true,
    },
  },
  methods: {
    dismiss() {
      axios
        .post(this.path, {
          feature_name: this.featureId,
        })
        .catch(e => {
          // eslint-disable-next-line @gitlab/require-i18n-strings, no-console
          console.error('Failed to dismiss message.', e);
        });

      this.$emit('dismiss');
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-display-flex gl-align-items-center">
      <slot name="title"></slot>
      <div class="ml-auto">
        <button
          :aria-label="__('Close')"
          class="btn-blank"
          type="button"
          data-testid="close"
          @click="dismiss"
        >
          <gl-icon name="close" class="gl-text-gray-500" />
        </button>
      </div>
    </div>
    <slot></slot>
  </div>
</template>
