<script>
/* eslint-disable @gitlab/vue-require-i18n-strings */
import { GlLink, GlTooltip, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { __ } from '~/locale';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import timeago from '~/vue_shared/mixins/timeago';

export default {
  components: {
    GlTooltip,
    GlLink,
    GlIcon,
    UserAvatarImage,
    TimeagoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeago],
  props: {
    suggestion: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isOpen() {
      return this.suggestion.state === 'opened';
    },
    isClosed() {
      return this.suggestion.state === 'closed';
    },
    counts() {
      return [
        {
          id: uniqueId(),
          icon: 'thumb-up',
          tooltipTitle: __('Upvotes'),
          count: this.suggestion.upvotes,
        },
        {
          id: uniqueId(),
          icon: 'comment',
          tooltipTitle: __('Comments'),
          count: this.suggestion.userNotesCount,
        },
      ].filter(({ count }) => count);
    },
    stateIcon() {
      return this.isClosed ? 'issue-close' : 'issue-open-m';
    },
    stateTitle() {
      return this.isClosed ? __('Closed') : __('Opened');
    },
    closedOrCreatedDate() {
      return this.suggestion.closedAt || this.suggestion.createdAt;
    },
    hasUpdated() {
      return this.suggestion.updatedAt !== this.suggestion.createdAt;
    },
  },
};
</script>

<template>
  <div class="suggestion-item">
    <div class="d-flex align-items-center">
      <gl-icon
        v-if="suggestion.confidential"
        v-gl-tooltip.bottom
        :title="__('Confidential')"
        name="eye-slash"
        class="suggestion-help-hover mr-1 suggestion-confidential"
      />
      <gl-link
        :href="suggestion.webUrl"
        target="_blank"
        class="suggestion bold str-truncated-100 gl-text-gray-900!"
      >
        {{ suggestion.title }}
      </gl-link>
    </div>
    <div class="text-secondary suggestion-footer">
      <gl-icon
        ref="state"
        :name="stateIcon"
        :class="{
          'suggestion-state-open': isOpen,
          'suggestion-state-closed': isClosed,
        }"
        class="suggestion-help-hover"
      />
      <gl-tooltip :target="() => $refs.state" placement="bottom">
        <span class="d-block">
          <span class="bold"> {{ stateTitle }} </span> {{ timeFormatted(closedOrCreatedDate) }}
        </span>
        <span class="text-tertiary">{{ tooltipTitle(closedOrCreatedDate) }}</span>
      </gl-tooltip>
      #{{ suggestion.iid }} &bull;
      <timeago-tooltip
        :time="suggestion.createdAt"
        tooltip-placement="bottom"
        class="suggestion-help-hover"
      />
      by
      <gl-link :href="suggestion.author.webUrl">
        <user-avatar-image
          :img-src="suggestion.author.avatarUrl"
          :size="16"
          css-classes="mr-0 float-none"
          tooltip-placement="bottom"
          class="d-inline-block"
        >
          <span class="bold d-block">{{ __('Author') }}</span> {{ suggestion.author.name }}
          <span class="text-tertiary">@{{ suggestion.author.username }}</span>
        </user-avatar-image>
      </gl-link>
      <template v-if="hasUpdated">
        &bull; {{ __('updated') }}
        <timeago-tooltip
          :time="suggestion.updatedAt"
          tooltip-placement="bottom"
          class="suggestion-help-hover"
        />
      </template>
      <span class="suggestion-counts">
        <span
          v-for="{ count, icon, tooltipTitle, id } in counts"
          :key="id"
          v-gl-tooltip.bottom
          :title="tooltipTitle"
          class="suggestion-help-hover gl-ml-3 text-tertiary"
        >
          <gl-icon :name="icon" /> {{ count }}
        </span>
      </span>
    </div>
  </div>
</template>
