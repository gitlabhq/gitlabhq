<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';

export default {
  components: {
    GlSprintf,
    GlLink,
  },
  props: {
    schedules: {
      type: Array,
      required: true,
    },
    userName: {
      type: String,
      required: false,
      default: null,
    },
    isCurrentUser: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    title() {
      return this.isCurrentUser
        ? s__('OnCallSchedules|You are currently a part of:')
        : sprintf(
            s__('OnCallSchedules|User %{name} is currently part of:'),
            {
              name: this.userName,
            },
            false,
          );
    },
    footer() {
      return this.isCurrentUser
        ? s__(
            'OnCallSchedules|Removing yourself may put your on-call team at risk of missing a notification.',
          )
        : s__(
            'OnCallSchedules|Removing this user may put their on-call team at risk of missing a notification.',
          );
    },
  },
};
</script>

<template>
  <div>
    <p data-testid="title">{{ title }}</p>

    <ul data-testid="schedules-list">
      <li v-for="(schedule, index) in schedules" :key="`${schedule.name}-${index}`">
        <gl-sprintf
          :message="s__('OnCallSchedules|On-call schedule %{schedule} in Project %{project}')"
        >
          <template #schedule>
            <gl-link :href="schedule.scheduleUrl" target="_blank">{{ schedule.name }}</gl-link>
          </template>
          <template #project>
            <gl-link :href="schedule.projectUrl" target="_blank">{{
              schedule.projectName
            }}</gl-link>
          </template>
        </gl-sprintf>
      </li>
    </ul>

    <p data-testid="footer">{{ footer }}</p>
  </div>
</template>
