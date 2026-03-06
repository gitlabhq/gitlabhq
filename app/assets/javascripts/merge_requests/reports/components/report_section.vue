<script>
import { GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import StatusIcon from '~/vue_merge_request_widget/components/widget/status_icon.vue';
import ActionButtons from '~/vue_merge_request_widget/components/widget/action_buttons.vue';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';

export default {
  name: 'ReportSection',
  components: {
    GlLink,
    HelpPopover,
    StatusIcon,
    ActionButtons,
  },
  directives: {
    SafeHtml,
  },
  props: {
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    summary: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    statusIconName: {
      type: String,
      required: false,
      default: 'neutral',
      validator: (value) => Object.keys(EXTENSION_ICONS).includes(value),
    },
    actionButtons: {
      type: Array,
      required: false,
      default: () => [],
    },
    helpPopover: {
      type: Object,
      required: false,
      default: null,
    },
    loadingText: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    hasActionButtons() {
      return this.actionButtons.length > 0;
    },
  },
  i18n: {
    learnMore: __('Learn more'),
  },
};
</script>

<template>
  <section class="media-section" data-testid="report">
    <div class="gl-flex gl-px-5 gl-py-4">
      <status-icon :level="1" :is-loading="isLoading" :icon-name="statusIconName" name="Report" />
      <div v-if="isLoading" class="media-body gl-flex !gl-flex-row gl-self-center">
        <div class="gl-grow" data-testid="loading-text">{{ loadingText }}</div>
      </div>
      <template v-else>
        <div class="media-body gl-flex !gl-flex-row gl-self-center">
          <div class="gl-grow">
            <span v-if="summary.title" v-safe-html="summary.title" data-testid="summary"></span>
          </div>
          <div class="gl-flex">
            <help-popover
              v-if="helpPopover"
              icon="information-o"
              :options="helpPopover.options"
              :class="{ 'gl-mr-3': hasActionButtons }"
            >
              <template v-if="helpPopover.content">
                <p
                  v-if="helpPopover.content.text"
                  v-safe-html="helpPopover.content.text"
                  class="gl-mb-0"
                ></p>
                <gl-link
                  v-if="helpPopover.content.learnMorePath"
                  :href="helpPopover.content.learnMorePath"
                  target="_blank"
                  class="gl-text-sm"
                  >{{ $options.i18n.learnMore }}</gl-link
                >
              </template>
            </help-popover>
            <action-buttons v-if="hasActionButtons" :tertiary-buttons="actionButtons" />
          </div>
        </div>
      </template>
    </div>
  </section>
</template>
