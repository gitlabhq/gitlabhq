<script>
import { GlCollapse, GlButton, GlIcon, GlSkeletonLoader, GlTableLite } from '@gitlab/ui';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { __, s__, formatNumber } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { createAlert } from '~/alert';
import runnerManagersQuery from '../graphql/show/runner_managers.query.graphql';
import { I18N_FETCH_ERROR } from '../constants';
import { captureException } from '../sentry_utils';
import { tableField } from '../utils';

export default {
  name: 'RunnerManagersDetail',
  components: {
    GlCollapse,
    GlButton,
    GlIcon,
    GlSkeletonLoader,
    GlTableLite,
    TimeAgo,
    HelpPopover,
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
    <gl-icon name="container-image" class="gl-text-secondary" />
    {{ runnerManagersCountFormatted }}
    <gl-button
      v-if="runnerManagersCount"
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
      <gl-table-lite v-else-if="managers.length" :fields="$options.fields" :items="managers">
        <template #head(systemId)="{ label }">
          {{ label }}
          <help-popover>
            {{ s__('Runners|The unique ID for each runner that uses this configuration.') }}
          </help-popover>
        </template>
        <template #cell(contactedAt)="{ item = {} }">
          <template v-if="item.contactedAt">
            <time-ago :time="item.contactedAt" />
          </template>
          <template v-else>{{ s__('Runners|Never contacted') }}</template>
        </template>
      </gl-table-lite>
    </gl-collapse>
  </div>
</template>
