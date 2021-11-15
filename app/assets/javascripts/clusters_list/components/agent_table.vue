<script>
import {
  GlLink,
  GlModalDirective,
  GlTable,
  GlIcon,
  GlSprintf,
  GlTooltip,
  GlPopover,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { helpPagePath } from '~/helpers/help_page_helper';
import { INSTALL_AGENT_MODAL_ID, AGENT_STATUSES } from '../constants';
import { getAgentConfigPath } from '../clusters_util';

export default {
  components: {
    GlLink,
    GlTable,
    GlIcon,
    GlSprintf,
    GlTooltip,
    GlPopover,
    TimeAgoTooltip,
  },
  directives: {
    GlModalDirective,
  },
  mixins: [timeagoMixin],
  INSTALL_AGENT_MODAL_ID,
  AGENT_STATUSES,

  troubleshooting_link: helpPagePath('user/clusters/agent/index', {
    anchor: 'troubleshooting',
  }),
  props: {
    agents: {
      required: true,
      type: Array,
    },
  },
  computed: {
    fields() {
      const tdClass = 'gl-py-5!';
      return [
        {
          key: 'name',
          label: s__('ClusterAgents|Name'),
          tdClass,
        },
        {
          key: 'status',
          label: s__('ClusterAgents|Connection status'),
          tdClass,
        },
        {
          key: 'lastContact',
          label: s__('ClusterAgents|Last contact'),
          tdClass,
        },
        {
          key: 'configuration',
          label: s__('ClusterAgents|Configuration'),
          tdClass,
        },
      ];
    },
  },
  methods: {
    getCellId(item) {
      return `connection-status-${item.name}`;
    },
    getAgentConfigPath,
  },
};
</script>

<template>
  <gl-table
    :items="agents"
    :fields="fields"
    stacked="md"
    head-variant="white"
    thead-class="gl-border-b-solid gl-border-b-2 gl-border-b-gray-100"
    class="gl-mb-4!"
    data-testid="cluster-agent-list-table"
  >
    <template #cell(name)="{ item }">
      <gl-link :href="item.webPath" data-testid="cluster-agent-name-link">
        {{ item.name }}
      </gl-link>
    </template>

    <template #cell(status)="{ item }">
      <span :id="getCellId(item)" class="gl-md-pr-5" data-testid="cluster-agent-connection-status">
        <span :class="$options.AGENT_STATUSES[item.status].class" class="gl-mr-3">
          <gl-icon :name="$options.AGENT_STATUSES[item.status].icon" :size="12" /></span
        >{{ $options.AGENT_STATUSES[item.status].name }}
      </span>
      <gl-tooltip v-if="item.status === 'active'" :target="getCellId(item)" placement="right">
        <gl-sprintf :message="$options.AGENT_STATUSES[item.status].tooltip.title"
          ><template #timeAgo>{{ timeFormatted(item.lastContact) }}</template>
        </gl-sprintf>
      </gl-tooltip>
      <gl-popover
        v-else
        :target="getCellId(item)"
        :title="$options.AGENT_STATUSES[item.status].tooltip.title"
        placement="right"
        container="viewport"
      >
        <p>
          <gl-sprintf :message="$options.AGENT_STATUSES[item.status].tooltip.body"
            ><template #timeAgo>{{ timeFormatted(item.lastContact) }}</template></gl-sprintf
          >
        </p>
        <p class="gl-mb-0">
          <gl-link :href="$options.troubleshooting_link" target="_blank" class="gl-font-sm">
            {{ s__('ClusterAgents|Learn how to troubleshoot') }}</gl-link
          >
        </p>
      </gl-popover>
    </template>

    <template #cell(lastContact)="{ item }">
      <span data-testid="cluster-agent-last-contact">
        <time-ago-tooltip v-if="item.lastContact" :time="item.lastContact" />
        <span v-else>{{ s__('ClusterAgents|Never') }}</span>
      </span>
    </template>

    <template #cell(configuration)="{ item }">
      <span data-testid="cluster-agent-configuration-link">
        <gl-link v-if="item.configFolder" :href="item.configFolder.webPath">
          {{ getAgentConfigPath(item.name) }}
        </gl-link>

        <span v-else>{{ getAgentConfigPath(item.name) }}</span>
      </span>
    </template>
  </gl-table>
</template>
