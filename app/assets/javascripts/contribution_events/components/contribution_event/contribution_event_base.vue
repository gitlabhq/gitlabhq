<script>
import { GlAvatarLabeled, GlAvatarLink, GlIcon, GlSprintf } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { VARIANT_DEFAULT, VARIANT_AVATAR } from '../../constants';
import { isValidVariant } from '../../utils';
import TargetLink from '../target_link.vue';
import ResourceParentLink from '../resource_parent_link.vue';

export default {
  components: {
    GlAvatarLabeled,
    GlAvatarLink,
    GlIcon,
    GlSprintf,
    TimeAgoTooltip,
    TargetLink,
    ResourceParentLink,
  },
  props: {
    event: {
      type: Object,
      required: true,
    },
    iconName: {
      type: String,
      required: true,
    },
    message: {
      type: String,
      required: false,
      default: '',
    },
    /**
     * Variant for styling. Options:
     * - 'default': Shows event with icon only
     * - 'avatar': Shows event with the author avatar
     */
    variant: {
      type: String,
      required: false,
      default: VARIANT_DEFAULT,
      validator: isValidVariant,
    },
  },
  computed: {
    isDefaultVariant() {
      return this.variant === VARIANT_DEFAULT;
    },
    author() {
      return this.event.author;
    },
    authorUsername() {
      return `@${this.author.username}`;
    },
    variantClass() {
      const classes = {
        [VARIANT_DEFAULT]: 'contribution-event-default',
        [VARIANT_AVATAR]: 'contribution-event-avatar',
      };

      return classes[this.variant];
    },
  },
};
</script>

<template>
  <li
    class="contribution-event gl-relative gl-pb-5 sm:gl-pb-6"
    :class="variantClass"
    data-testid="contribution-event"
  >
    <div
      class="contribution-event-icon"
      :class="{
        'gl-flex gl-h-6 gl-w-6 gl-items-center gl-justify-center gl-rounded-full gl-bg-strong':
          isDefaultVariant,
      }"
    >
      <gl-icon :name="iconName" :size="16" />
    </div>

    <gl-avatar-link
      v-if="!isDefaultVariant"
      :href="author.web_url"
      class="contribution-event-author gl-flex gl-items-center"
    >
      <gl-avatar-labeled
        :label="author.name"
        :sub-label="authorUsername"
        inline-labels
        :src="author.avatar_url"
        :size="24"
      />
    </gl-avatar-link>

    <div
      class="contribution-event-title"
      :class="{ 'gl-text-subtle': !isDefaultVariant }"
      data-testid="event-title"
    >
      <span :class="{ 'gl-font-semibold': isDefaultVariant }">
        <gl-sprintf v-if="message" :message="message">
          <template #targetLink>
            <span class="gl-font-normal">
              <target-link :event="event" />
            </span>
          </template>
          <template #resourceParentLink>
            <span class="gl-font-normal">
              <resource-parent-link :event="event" />
            </span>
          </template>
        </gl-sprintf>
        <slot v-else></slot>
      </span>
    </div>

    <time-ago-tooltip
      class="contribution-event-timestamp gl-text-sm gl-text-subtle"
      :time="event.created_at"
    />

    <div v-if="$scopedSlots['additional-info']" class="contribution-event-description">
      <slot name="additional-info"></slot>
    </div>
  </li>
</template>
