<script>
import { GlPopover, GlButton, GlLink } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import axios from '~/lib/utils/axios_utils';

export default {
  components: {
    GlPopover,
    GlButton,
    GlLink,
    Icon,
  },
  props: {
    dismissEndpoint: {
      type: String,
      required: true,
    },
    featureId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      showPopover: false,
    };
  },
  mounted() {
    setTimeout(() => {
      this.showPopover = true;
    }, 2000);
  },
  methods: {
    onDismiss() {
      this.showPopover = false;

      axios.post(this.dismissEndpoint, {
        feature_name: this.featureId,
      });
    },
  },
};
</script>

<template>
  <gl-popover target="#diffs-tab" placement="bottom" :show="showPopover">
    <p class="mb-2">
      {{
        __(
          'Now you can access the merge request navigation tabs at the top, where they’re easier to find.',
        )
      }}
    </p>
    <p>
      <gl-link href="https://gitlab.com/gitlab-org/gitlab/issues/36125" target="_blank">
        {{ __('More information and share feedback') }}
        <icon name="external-link" :size="10" />
      </gl-link>
    </p>
    <gl-button
      variant="primary"
      size="sm"
      data-qa-selector="dismiss_popover_button"
      @click="onDismiss"
    >
      {{ __('Got it') }}
    </gl-button>
  </gl-popover>
</template>
