<script>
import { GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { EXTENSION_ICONS } from '../../constants';
import { generateText } from './utils';
import ActionButtons from './action_buttons.vue';
import StatusIcon from './status_icon.vue';

export default {
  components: {
    StatusIcon,
    HelpPopover,
    GlLink,
    ActionButtons,
  },
  directives: {
    SafeHtml,
  },
  props: {
    level: {
      type: Number,
      required: true,
      validator: (value) => value === 2 || value === 3,
    },
    statusIconName: {
      type: String,
      required: false,
      default: '',
      validator: (value) => value === '' || Object.keys(EXTENSION_ICONS).includes(value),
    },
    widgetName: {
      type: String,
      required: true,
    },
    header: {
      type: [String, Array],
      required: false,
      default: '',
    },
    /**
     * @typedef {Object} helpPopover
     * @property {Object} options
     * @property {String} options.title
     * @property {Object} content
     * @property {String} content.text
     * @property {String} content.learnMorePath
     */
    helpPopover: {
      type: Object,
      required: false,
      default: null,
    },
    actionButtons: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    generatedHeader() {
      return generateText(Array.isArray(this.header) ? this.header[0] : this.header);
    },
    generatedSubheader() {
      return Array.isArray(this.header) && this.header[1] ? generateText(this.header[1]) : '';
    },
    shouldShowHeaderActions() {
      return Boolean(this.helpPopover) || this.actionButtons?.length > 0;
    },
    hasActionButtons() {
      return this.actionButtons.length > 0;
    },
  },
  methods: {
    hasHeader() {
      return Boolean(this.$scopedSlots.header || this.header || this.shouldShowHeaderActions);
    },
  },
  i18n: {
    learnMore: __('Learn more'),
  },
};
</script>
<template>
  <div
    class="gl-flex"
    :class="{
      'gl-border-t gl-border-t-section gl-py-3 gl-pl-7': level === 2,
    }"
  >
    <status-icon
      v-if="statusIconName && !header"
      :level="2"
      :name="widgetName"
      :icon-name="statusIconName"
    />
    <div class="gl-w-full gl-min-w-0">
      <div v-if="hasHeader()" class="gl-flex">
        <slot name="header">
          <div class="gl-mb-2">
            <strong v-safe-html="generatedHeader" class="gl-block"></strong
            ><span
              v-if="generatedSubheader"
              v-safe-html="generatedSubheader"
              class="gl-block"
            ></span>
          </div>
        </slot>
        <div v-if="shouldShowHeaderActions" class="gl-ml-auto gl-flex gl-items-baseline">
          <help-popover
            v-if="helpPopover"
            :options="helpPopover.options"
            :class="{ 'gl-mr-3': hasActionButtons }"
            icon="information-o"
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
      <div class="gl-flex gl-items-baseline">
        <status-icon
          v-if="statusIconName && header"
          :level="2"
          :name="widgetName"
          :icon-name="statusIconName"
        />
        <slot name="body"></slot>
      </div>
    </div>
  </div>
</template>
