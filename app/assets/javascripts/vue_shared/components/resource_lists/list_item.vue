<script>
import { GlAvatarLabeled, GlIcon, GlTooltipDirective } from '@gitlab/ui';

import { __ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import ListActions from '~/vue_shared/components/list_actions/list_actions.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import {
  TIMESTAMP_TYPES,
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
  TIMESTAMP_TYPE_LAST_ACTIVITY_AT,
} from '~/vue_shared/components/resource_lists/constants';
import ListItemDescription from './list_item_description.vue';

export default {
  i18n: {
    [TIMESTAMP_TYPE_CREATED_AT]: __('Created'),
    [TIMESTAMP_TYPE_UPDATED_AT]: __('Updated'),
    [TIMESTAMP_TYPE_LAST_ACTIVITY_AT]: __('Updated'),
  },
  components: {
    GlAvatarLabeled,
    GlIcon,
    ListActions,
    TimeAgoTooltip,
    ListItemDescription,
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
        const requiredKeys = ['id', 'avatarUrl', 'avatarLabel', 'webUrl'];

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
        return TIMESTAMP_TYPES.includes(value);
      },
    },
    contentTestid: {
      type: String,
      required: false,
      default: null,
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
      return (
        this.$scopedSlots.actions ||
        (Object.keys(this.actions).length && this.resource.availableActions?.length)
      );
    },
  },
};
</script>

<template>
  <li class="gl-border-b gl-flex gl-items-start gl-py-4">
    <div class="gl-grow gl-items-start md:gl-flex">
      <div class="gl-flex gl-grow" :data-testid="contentTestid">
        <div v-if="showIcon" class="gl-mr-3 gl-flex gl-h-7 gl-shrink-0 gl-items-center">
          <gl-icon variant="subtle" :name="iconName" />
        </div>
        <gl-avatar-labeled
          class="gl-break-anywhere"
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
          <slot name="avatar-default">
            <list-item-description
              v-if="resource.descriptionHtml"
              :description-html="resource.descriptionHtml"
            />
          </slot>
        </gl-avatar-labeled>
      </div>
      <div
        class="gl-mt-3 gl-shrink-0 gl-flex-col gl-items-end md:gl-mt-0 md:gl-flex md:gl-pl-3"
        :class="statsPadding"
      >
        <div class="gl-flex gl-items-center gl-gap-x-3 md:gl-h-5">
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
    <div v-if="hasActions" class="-gl-mt-3 gl-ml-3 gl-flex gl-items-center">
      <slot name="actions">
        <list-actions :actions="actions" :available-actions="resource.availableActions" />
      </slot>
    </div>

    <slot name="footer"></slot>
  </li>
</template>
