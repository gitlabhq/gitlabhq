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
        .catch((e) => {
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
    <div class="gl-flex gl-items-center">
      <slot name="title"></slot>
      <div class="ml-auto">
        <button
          :aria-label="__('Close')"
          class="gl-rounded-none gl-border-none !gl-bg-transparent gl-p-0 !gl-shadow-none !gl-outline-none"
          type="button"
          data-testid="close"
          @click="dismiss"
        >
          <gl-icon name="close" variant="subtle" />
        </button>
      </div>
    </div>
    <slot></slot>
  </div>
</template>
