<script>
import { GlLink, GlIcon, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import HistoryItem from '~/vue_shared/components/registry/history_item.vue';
import { EVENT_DETAILS, DEFAULT_ICON } from '../constants';

export default {
  i18n: {
    defaultBodyText: s__('ClusterAgents|Event occurred'),
  },
  components: {
    GlLink,
    GlIcon,
    GlSprintf,
    TimeAgoTooltip,
    HistoryItem,
  },
  props: {
    event: {
      required: true,
      type: Object,
    },
    bodyClass: {
      required: false,
      default: '',
      type: String,
    },
  },
  computed: {
    eventDetails() {
      const defaultEvent = {
        eventTypeIcon: DEFAULT_ICON,
        title: this.event.kind,
        body: this.$options.i18n.defaultBodyText,
      };

      const eventDetails = EVENT_DETAILS[this.event.kind] || defaultEvent;
      const { eventTypeIcon, title, body, titleIcon } = eventDetails;
      const resultEvent = { ...this.event, eventTypeIcon, title, body, titleIcon };

      return resultEvent;
    },
  },
};
</script>
<template>
  <history-item :icon="eventDetails.eventTypeIcon" class="!gl-my-0 !gl-px-0 !gl-pb-0">
    <strong class="gl-pl-3 gl-text-lg">
      <gl-sprintf :message="eventDetails.title"
        ><template v-if="eventDetails.titleIcon" #titleIcon
          ><gl-icon
            class="gl-mr-2"
            :name="eventDetails.titleIcon.name"
            :size="12"
            :class="eventDetails.titleIcon.class"
          />
        </template>
        <template #tokenName>{{ eventDetails.agentToken.name }}</template></gl-sprintf
      >
    </strong>

    <template #body>
      <p class="gl-mb-0 gl-ml-3 gl-mt-2 gl-pb-3 gl-text-subtle" :class="bodyClass">
        <gl-sprintf :message="eventDetails.body">
          <template #userName>
            <span class="gl-font-bold gl-text-default">{{ eventDetails.user.name }}</span>
            <gl-link :href="eventDetails.user.webUrl">@{{ eventDetails.user.username }}</gl-link>
          </template>

          <template #strong="{ content }">
            <span class="gl-font-bold gl-text-default"> {{ content }} </span>
          </template>
        </gl-sprintf>
        <time-ago-tooltip :time="eventDetails.recordedAt" />
      </p>
    </template>
  </history-item>
</template>
