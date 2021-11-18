<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import { OBSTACLE_TYPES } from './constants';

const OBSTACLE_TEXT = {
  [OBSTACLE_TYPES.oncallSchedules]: s__(
    'OnCallSchedules|On-call schedule %{obstacle} in project %{project}',
  ),
  [OBSTACLE_TYPES.escalationPolicies]: s__(
    'EscalationPolicies|Escalation policy %{obstacle} in project %{project}',
  ),
};

export default {
  components: {
    GlSprintf,
    GlLink,
  },
  props: {
    obstacles: {
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
  methods: {
    textForObstacle(obstacle) {
      return OBSTACLE_TEXT[obstacle.type];
    },
    urlForObstacle(obstacle) {
      // Fallback to scheduleUrl for backwards compatibility
      return obstacle.url || obstacle.scheduleUrl;
    },
  },
};
</script>

<template>
  <div>
    <p data-testid="title">{{ title }}</p>

    <ul data-testid="obstacles-list">
      <li v-for="(obstacle, index) in obstacles" :key="`${obstacle.name}-${index}`">
        <gl-sprintf :message="textForObstacle(obstacle)">
          <template #obstacle>
            <gl-link :href="urlForObstacle(obstacle)" target="_blank">{{ obstacle.name }}</gl-link>
          </template>
          <template #project>
            <gl-link :href="obstacle.projectUrl" target="_blank">{{
              obstacle.projectName
            }}</gl-link>
          </template>
        </gl-sprintf>
      </li>
    </ul>

    <p data-testid="footer">{{ footer }}</p>
  </div>
</template>
