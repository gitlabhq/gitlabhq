<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__, formatNumber } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { tableField } from '../utils';
import RunnerManagersTable from './runner_managers_table.vue';

export default {
  name: 'RunnerManagers',
  components: {
    GlLink,
    GlSprintf,
    RunnerManagersTable,
    CrudComponent,
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
  computed: {
    items() {
      return this.runner?.managers?.nodes;
    },
    count() {
      return this.runner?.managers?.count || 0;
    },
    formattedCount() {
      return formatNumber(this.count);
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
  <crud-component
    v-if="count > 0"
    :title="s__('Runners|Runners')"
    icon="container-image"
    :count="formattedCount"
    anchor-id="runner-managers"
    is-collapsible
    collapsed
    persist-collapsed-state
    class="!gl-mt-0"
    data-testid="runner-managers"
  >
    <template #count>
      <help-popover>
        <gl-sprintf
          :message="
            s__(
              'Runners|Runners are grouped when they have the same authentication token. This happens when you re-use a runner configuration in more than one runner manager. %{linkStart}How does this work?%{linkEnd}',
            )
          "
        >
          <template #link="{ content }"
            ><gl-link :href="$options.RUNNER_MANAGERS_HELP_URL" target="_blank">{{
              content
            }}</gl-link></template
          >
        </gl-sprintf>
      </help-popover>
    </template>

    <runner-managers-table :items="items" />
  </crud-component>
</template>
