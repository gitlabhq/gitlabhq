<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import { searchValidator } from '~/runner/runner_search_utils';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '../constants';

const tabs = [
  {
    title: s__('Runners|All'),
    runnerType: null,
  },
  {
    title: s__('Runners|Instance'),
    runnerType: INSTANCE_TYPE,
  },
  {
    title: s__('Runners|Group'),
    runnerType: GROUP_TYPE,
  },
  {
    title: s__('Runners|Project'),
    runnerType: PROJECT_TYPE,
  },
];

export default {
  components: {
    GlTabs,
    GlTab,
  },
  props: {
    value: {
      type: Object,
      required: true,
      validator: searchValidator,
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
  tabs,
};
</script>
<template>
  <gl-tabs v-bind="$attrs" data-testid="runner-type-tabs">
    <gl-tab
      v-for="tab in $options.tabs"
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
