<script>
import clusterPopover from '@gitlab/svgs/dist/illustrations/cluster_popover.svg';
import {
  GlPopover,
  GlSprintf,
  GlLink,
  GlButton,
  GlSafeHtmlDirective as SafeHtml,
} from '@gitlab/ui';
import { __ } from '~/locale';
import { POPOVER_TARGET_ID } from './constants';
import { dismiss } from './feature_highlight_helper';

export default {
  components: {
    GlPopover,
    GlSprintf,
    GlLink,
    GlButton,
  },
  directives: {
    SafeHtml,
  },
  props: {
    autoDevopsHelpPath: {
      type: String,
      required: true,
    },
    highlightId: {
      type: String,
      required: true,
    },
    dismissEndpoint: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      dismissed: false,
      triggerHidden: false,
    };
  },
  methods: {
    dismiss() {
      dismiss(this.dismissEndpoint, this.highlightId);
      this.$refs.popover.$emit('close');
      this.dismissed = true;
    },
    hideTrigger() {
      if (this.dismissed) {
        this.triggerHidden = true;
      }
    },
  },
  clusterPopover,
  targetId: POPOVER_TARGET_ID,
  i18n: {
    highlightMessage: __('Allows you to add and manage Kubernetes clusters.'),
    autoDevopsProTipMessage: __(
      'Protip: %{linkStart}Auto DevOps%{linkEnd} uses Kubernetes clusters to deploy your code!',
    ),
    dismissButtonLabel: __('Got it!'),
  },
};
</script>
<template>
  <div class="gl-ml-3">
    <span v-if="!triggerHidden" :id="$options.targetId" class="feature-highlight"></span>
    <gl-popover
      ref="popover"
      :target="$options.targetId"
      :css-classes="['feature-highlight-popover']"
      container="body"
      placement="right"
      boundary="viewport"
      @hidden="hideTrigger"
    >
      <span
        v-safe-html="$options.clusterPopover"
        class="feature-highlight-illustration gl-display-flex gl-justify-content-center gl-py-4 gl-w-full"
      ></span>
      <div class="gl-px-4 gl-py-5">
        <p>
          {{ $options.i18n.highlightMessage }}
        </p>
        <p>
          <gl-sprintf :message="$options.i18n.autoDevopsProTipMessage">
            <template #link="{ content }">
              <gl-link class="gl-font-sm" :href="autoDevopsHelpPath">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </p>
        <gl-button size="small" icon="thumb-up" variant="confirm" @click="dismiss">
          {{ $options.i18n.dismissButtonLabel }}
        </gl-button>
      </div>
    </gl-popover>
  </div>
</template>
