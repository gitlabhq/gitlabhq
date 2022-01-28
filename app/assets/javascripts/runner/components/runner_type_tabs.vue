<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import { searchValidator } from '~/runner/runner_search_utils';
import {
  INSTANCE_TYPE,
  GROUP_TYPE,
  PROJECT_TYPE,
  I18N_ALL_TYPES,
  I18N_INSTANCE_TYPE,
  I18N_GROUP_TYPE,
  I18N_PROJECT_TYPE,
} from '../constants';

const I18N_TAB_TITLES = {
  [INSTANCE_TYPE]: I18N_INSTANCE_TYPE,
  [GROUP_TYPE]: I18N_GROUP_TYPE,
  [PROJECT_TYPE]: I18N_PROJECT_TYPE,
};

export default {
  components: {
    GlTabs,
    GlTab,
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
          runnerType: null,
        },
        ...tabs,
      ];
    },
  },
  methods: {
    onTabSelected({ runnerType }) {
      this.$emit('input', {
        ...this.value,
        runnerType,
        pagination: { page: 1 },
      });
    },
    isTabActive({ runnerType }) {
      return runnerType === this.value.runnerType;
    },
  },
};
</script>
<template>
  <gl-tabs v-bind="$attrs" data-testid="runner-type-tabs">
    <gl-tab
      v-for="tab in tabs"
      :key="`${tab.runnerType}`"
      :active="isTabActive(tab)"
      @click="onTabSelected(tab)"
    >
      <template #title>
        <slot name="title" :tab="tab">{{ tab.title }}</slot>
      </template>
    </gl-tab>
  </gl-tabs>
</template>
