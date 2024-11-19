<script>
import { GlCollapse, GlButton, GlIcon, GlSkeletonLoader } from '@gitlab/ui';
import { __, s__, formatNumber } from '~/locale';
import { createAlert } from '~/alert';
import runnerManagersQuery from '../graphql/show/runner_managers.query.graphql';
import { I18N_FETCH_ERROR } from '../constants';
import { captureException } from '../sentry_utils';
import { tableField } from '../utils';
import RunnerManagersTable from './runner_managers_table.vue';

export default {
  name: 'RunnerManagersDetail',
  components: {
    GlCollapse,
    GlButton,
    GlIcon,
    GlSkeletonLoader,
    RunnerManagersTable,
  },
  props: {
    runner: {
      type: Object,
      required: true,
      validator: (runner) => {
        return Boolean(runner?.id);
      },
    },
  },
  data() {
    return {
      skip: true,
      expanded: false,
      managers: [],
    };
  },
  apollo: {
    managers: {
      query: runnerManagersQuery,
      skip() {
        return this.skip;
      },
      variables() {
        return { runnerId: this.runner.id };
      },
      update({ runner }) {
        return runner?.managers?.nodes || [];
      },
      error(error) {
        createAlert({ message: I18N_FETCH_ERROR });
        captureException({ error, component: this.$options.name });
      },
    },
  },
  computed: {
    runnerManagersCount() {
      return this.runner?.managers?.count || 0;
    },
    runnerManagersCountFormatted() {
      return formatNumber(this.runnerManagersCount);
    },
    icon() {
      return this.expanded ? 'chevron-down' : 'chevron-right';
    },
    text() {
      return this.expanded ? __('Hide details') : __('Show details');
    },
    loading() {
      return this.$apollo?.queries.managers.loading;
    },
  },
  methods: {
    fetchManagers() {
      this.skip = false;
    },
    toggleExpanded() {
      this.expanded = !this.expanded;
    },
  },
  fields: [
    tableField({ key: 'systemId', label: s__('Runners|System ID') }),
    tableField({
      key: 'contactedAt',
      label: s__('Runners|Last contact'),
      tdClass: ['gl-text-right'],
      thClasses: ['gl-text-right'],
    }),
  ],
};
</script>

<template>
  <div>
    <gl-icon name="container-image" variant="subtle" />
    {{ runnerManagersCountFormatted }}
    <gl-button
      v-if="runnerManagersCount"
      data-testid="runner-button"
      variant="link"
      @mouseover.once="fetchManagers"
      @focus.once="fetchManagers"
      @click.once="fetchManagers"
      @click="toggleExpanded"
    >
      <gl-icon :name="icon" /> {{ text }}
    </gl-button>

    <gl-collapse :visible="expanded" class="gl-mt-5">
      <gl-skeleton-loader v-if="loading" />
      <runner-managers-table v-else-if="managers.length" :items="managers" />
    </gl-collapse>
  </div>
</template>
