<script>
import { GlAvatarLabeled, GlIcon, GlTooltipDirective, GlTruncateText } from '@gitlab/ui';

import { __ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';

export default {
  i18n: {
    showMore: __('Show more'),
    showLess: __('Show less'),
    [TIMESTAMP_TYPE_CREATED_AT]: __('Created'),
    [TIMESTAMP_TYPE_UPDATED_AT]: __('Updated'),
  },
  truncateTextToggleButtonProps: { class: '!gl-text-sm' },
  components: {
    GlAvatarLabeled,
    GlIcon,
    GlTruncateText,
    ListActions,
    TimeAgoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  props: {
    resource: {
      type: Object,
      required: true,
      validator(resource) {
        const requiredKeys = ['id', 'avatarUrl', 'avatarLabel', 'webUrl', 'availableActions'];

        return requiredKeys.every((key) => Object.prototype.hasOwnProperty.call(resource, key));
      },
    },
    showIcon: {
      type: Boolean,
      required: false,
      default: false,
    },
    iconName: {
      type: String,
      required: false,
      default: null,
    },
    actions: {
      type: Object,
      required: false,
      default() {
        return {};
      },
    },
    timestampType: {
      type: String,
      required: false,
      default: TIMESTAMP_TYPE_CREATED_AT,
      validator(value) {
        return [TIMESTAMP_TYPE_CREATED_AT, TIMESTAMP_TYPE_UPDATED_AT].includes(value);
      },
    },
  },
  computed: {
    statsPadding() {
      return this.showIcon ? 'gl-pl-11' : 'gl-pl-8';
    },
    timestamp() {
      return this.resource[this.timestampType];
    },
    timestampText() {
      return this.$options.i18n[this.timestampType];
    },
    hasActions() {
      return Object.keys(this.actions).length && this.resource.availableActions?.length;
    },
  },
};
</script>

<template>
  <li class="gl-border-b gl-flex gl-items-start gl-py-4">
    <div class="gl-grow gl-items-start md:gl-flex">
      <div class="gl-flex gl-grow">
        <div v-if="showIcon" class="gl-mr-3 gl-flex gl-h-7 gl-shrink-0 gl-items-center">
          <gl-icon variant="subtle" :name="iconName" />
        </div>
        <gl-avatar-labeled
          :entity-id="resource.id"
          :entity-name="resource.avatarLabel"
          :label="resource.avatarLabel"
          :label-link="resource.webUrl"
          :src="resource.avatarUrl"
          shape="rect"
          :size="32"
        >
          <template #meta>
            <div class="gl-px-1">
              <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-2">
                <slot name="avatar-meta"></slot>
              </div>
            </div>
          </template>
          <gl-truncate-text
            v-if="resource.descriptionHtml"
            :lines="2"
            :mobile-lines="2"
            :show-more-text="$options.i18n.showMore"
            :show-less-text="$options.i18n.showLess"
            :toggle-button-props="$options.truncateTextToggleButtonProps"
            class="gl-mt-2 gl-max-w-88"
          >
            <div
              v-safe-html="resource.descriptionHtml"
              class="md md-child-content-text-subtle gl-text-sm"
              data-testid="description"
            ></div>
          </gl-truncate-text>
        </gl-avatar-labeled>
      </div>
      <div
        class="gl-mt-3 gl-shrink-0 gl-flex-col gl-items-end md:gl-mt-0 md:gl-flex md:gl-pl-0"
        :class="statsPadding"
      >
        <div class="gl-flex gl-items-center gl-gap-x-3">
          <slot name="stats"></slot>
        </div>
        <div
          v-if="timestamp"
          class="gl-mt-2 gl-whitespace-nowrap gl-text-sm gl-leading-1 gl-text-subtle"
        >
          <span>{{ timestampText }}</span>
          <time-ago-tooltip :time="timestamp" />
        </div>
      </div>
    </div>
    <div class="-gl-mt-3 gl-ml-3 gl-flex gl-items-center">
      <list-actions
        v-if="hasActions"
        :actions="actions"
        :available-actions="resource.availableActions"
      />
    </div>

    <slot name="footer"></slot>
  </li>
</template>
