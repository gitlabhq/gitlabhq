<script>
import { GlLink, GlTooltip, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { STATUS_CLOSED } from '~/issues/constants';
import { __ } from '~/locale';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import timeago from '~/vue_shared/mixins/timeago';

export default {
  name: 'TitleSuggestionsItem',
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
    isClosed() {
      return this.suggestion.state === STATUS_CLOSED;
    },
    stateIconClass() {
      return this.isClosed ? 'gl-fill-icon-info' : 'gl-fill-icon-success';
    },
    stateIconName() {
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
    <div class="gl-flex gl-items-center">
      <gl-icon
        v-if="suggestion.confidential"
        v-gl-tooltip.bottom
        :title="__('Confidential')"
        name="eye-slash"
        class="gl-mr-2 gl-cursor-help"
        variant="warning"
      />
      <gl-link
        :href="suggestion.webUrl"
        target="_blank"
        class="suggestion str-truncated-100 gl-font-bold !gl-text-default"
      >
        {{ suggestion.title }}
      </gl-link>
    </div>
    <div class="suggestion-footer gl-flex gl-justify-between gl-gap-2 gl-text-sm gl-text-subtle">
      <div class="gl-inline-flex gl-items-center gl-gap-2">
        <div ref="state" class="gl-mb-1 gl-inline-flex gl-self-center">
          <gl-icon
            :name="stateIconName"
            :class="stateIconClass"
            class="gl-cursor-help"
            :size="14"
          />
        </div>

        <gl-tooltip :target="() => $refs.state" placement="bottom">
          <span class="gl-block">
            <span class="gl-font-bold"> {{ stateTitle }} </span>
            {{ timeFormatted(closedOrCreatedDate) }}
          </span>
          <span class="gl-text-subtle">{{ tooltipTitle(closedOrCreatedDate) }}</span>
        </gl-tooltip>
        #{{ suggestion.iid }} &bull;
        {{ __('opened') }}
        <timeago-tooltip
          :time="suggestion.createdAt"
          tooltip-placement="bottom"
          class="gl-cursor-help"
        />
        {{ __('by') }}
        <gl-link :href="suggestion.author.webUrl">
          <user-avatar-image
            :img-src="suggestion.author.avatarUrl"
            :size="16"
            tooltip-placement="bottom"
            class="gl-inline-block"
          >
            <span class="gl-block gl-font-bold">{{ __('Author') }}</span>
            {{ suggestion.author.name }}
            <span class="gl-text-subtle">@{{ suggestion.author.username }}</span>
          </user-avatar-image>
        </gl-link>
      </div>

      <div v-if="hasUpdated">
        {{ __('updated') }}
        <timeago-tooltip
          :time="suggestion.updatedAt"
          tooltip-placement="bottom"
          class="gl-cursor-help"
        />
      </div>
    </div>
  </div>
</template>
