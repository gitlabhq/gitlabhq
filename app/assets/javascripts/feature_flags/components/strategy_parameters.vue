<script>
import {
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_FLEXIBLE_ROLLOUT,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_USER_ID,
  ROLLOUT_STRATEGY_GITLAB_USER_LIST,
} from '../constants';

import Default from './strategies/default.vue';
import FlexibleRollout from './strategies/flexible_rollout.vue';
import GitlabUserList from './strategies/gitlab_user_list.vue';
import PercentRollout from './strategies/percent_rollout.vue';
import UsersWithId from './strategies/users_with_id.vue';

const STRATEGIES = Object.freeze({
  [ROLLOUT_STRATEGY_ALL_USERS]: Default,
  [ROLLOUT_STRATEGY_FLEXIBLE_ROLLOUT]: FlexibleRollout,
  [ROLLOUT_STRATEGY_PERCENT_ROLLOUT]: PercentRollout,
  [ROLLOUT_STRATEGY_USER_ID]: UsersWithId,
  [ROLLOUT_STRATEGY_GITLAB_USER_LIST]: GitlabUserList,
});

export default {
  props: {
    strategy: {
      type: Object,
      required: true,
    },
  },
  computed: {
    strategyComponent() {
      return STRATEGIES[this.strategy?.name];
    },
  },
  methods: {
    onChange(value) {
      this.$emit('change', {
        ...this.strategy,
        ...value,
      });
    },
  },
};
</script>
<template>
  <component
    :is="strategyComponent"
    v-if="strategyComponent"
    :strategy="strategy"
    v-bind="$attrs"
    @change="onChange"
  />
</template>
