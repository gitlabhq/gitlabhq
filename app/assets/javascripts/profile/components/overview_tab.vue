<script>
import { GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import ActivityCalendar from './activity_calendar.vue';

export default {
  i18n: {
    title: s__('UserProfile|Overview'),
  },
  components: { GlTab, ActivityCalendar },
};
</script>

<template>
  <gl-tab :title="$options.i18n.title">
    <activity-calendar />
  </gl-tab>
</template>
