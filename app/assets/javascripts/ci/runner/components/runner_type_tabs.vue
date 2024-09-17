<script>
import { GlBadge, GlTabs, GlTab } from '@gitlab/ui';
import { searchValidator } from '~/ci/runner/runner_search_utils';
import { formatNumber } from '~/locale';
import {
  INSTANCE_TYPE,
  GROUP_TYPE,
  PROJECT_TYPE,
  I18N_ALL_TYPES,
  I18N_INSTANCE_TYPE,
  I18N_GROUP_TYPE,
  I18N_PROJECT_TYPE,
} from '../constants';
import RunnerCount from './stat/runner_count.vue';

const I18N_TAB_TITLES = {
  [INSTANCE_TYPE]: I18N_INSTANCE_TYPE,
  [GROUP_TYPE]: I18N_GROUP_TYPE,
  [PROJECT_TYPE]: I18N_PROJECT_TYPE,
};

const TAB_COUNT_REF = 'tab-count';

export default {
  components: {
    GlBadge,
    GlTabs,
    GlTab,
    RunnerCount,
  },
  props: {
    runnerTypes: {
      type: Array,
      required: false,
      default: () => [INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE],
    },
    value: {
      type: Object,
      required: true,
      validator: searchValidator,
    },
    countScope: {
      type: String,
      required: true,
    },
    countVariables: {
      type: Object,
      required: true,
    },
  },
  computed: {
    tabs() {
      const tabs = this.runnerTypes.map((runnerType) => ({
        title: I18N_TAB_TITLES[runnerType],
        runnerType,
      }));

      // Always add a "All" tab that resets filters
      return [
        {
          title: I18N_ALL_TYPES,
        },
        ...tabs,
      ];
    },
  },
  methods: {
    onTabSelected(runnerType) {
      this.$emit('input', {
        ...this.value,
        runnerType,
        pagination: { page: 1 },
      });
    },
    isTabActive(runnerType = null) {
      return runnerType === this.value.runnerType;
    },
    tabBadgeCountVariables(runnerType) {
      return { ...this.countVariables, type: runnerType };
    },
    tabCount(count) {
      if (typeof count === 'number') {
        return formatNumber(count);
      }
      return '';
    },

    // Component API
    refetch() {
      // Refresh all of the counts here, can be called by parent component
      this.$refs[TAB_COUNT_REF].forEach((countComponent) => {
        countComponent.refetch();
      });
    },
  },
  TAB_COUNT_REF,
};
</script>
<template>
  <gl-tabs
    class="gl-w-full"
    content-class="gl-hidden"
    nav-class="!gl-border-none"
    data-testid="runner-type-tabs"
  >
    <gl-tab
      v-for="tab in tabs"
      :key="`${tab.runnerType}`"
      :active="isTabActive(tab.runnerType)"
      @click="onTabSelected(tab.runnerType)"
    >
      <template #title>
        {{ tab.title }}
        <runner-count
          #default="{ count }"
          :ref="$options.TAB_COUNT_REF"
          :scope="countScope"
          :variables="tabBadgeCountVariables(tab.runnerType)"
        >
          <gl-badge
            v-if="tabCount(count)"
            class="gl-ml-1"
            :data-testid="`runner-count-${tab.title.toLowerCase()}`"
          >
            {{ tabCount(count) }}
          </gl-badge>
        </runner-count>
      </template>
    </gl-tab>
  </gl-tabs>
</template>
