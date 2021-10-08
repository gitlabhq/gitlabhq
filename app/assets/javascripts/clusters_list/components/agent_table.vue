<script>
import {
  GlButton,
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
import { INSTALL_AGENT_MODAL_ID, AGENT_STATUSES, TROUBLESHOOTING_LINK } from '../constants';

export default {
  components: {
    GlButton,
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
  inject: ['integrationDocsUrl'],
  INSTALL_AGENT_MODAL_ID,
  AGENT_STATUSES,
  TROUBLESHOOTING_LINK,
  props: {
    agents: {
      required: true,
      type: Array,
    },
  },
  computed: {
    fields() {
      return [
        {
          key: 'name',
          label: s__('ClusterAgents|Name'),
        },
        {
          key: 'status',
          label: s__('ClusterAgents|Connection status'),
        },
        {
          key: 'lastContact',
          label: s__('ClusterAgents|Last contact'),
        },
        {
          key: 'configuration',
          label: s__('ClusterAgents|Configuration'),
        },
      ];
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-display-block gl-text-right gl-my-3">
      <gl-button
        v-gl-modal-directive="$options.INSTALL_AGENT_MODAL_ID"
        variant="confirm"
        category="primary"
        >{{ s__('ClusterAgents|Install a new GitLab Agent') }}
      </gl-button>
    </div>

    <gl-table
      :items="agents"
      :fields="fields"
      stacked="md"
      head-variant="white"
      thead-class="gl-border-b-solid gl-border-b-1 gl-border-b-gray-100"
      data-testid="cluster-agent-list-table"
    >
      <template #cell(name)="{ item }">
        <gl-link :href="item.webPath" data-testid="cluster-agent-name-link">
          {{ item.name }}
        </gl-link>
      </template>

      <template #cell(status)="{ item }">
        <span
          :id="`connection-status-${item.name}`"
          class="gl-pr-5"
          data-testid="cluster-agent-connection-status"
        >
          <span :class="$options.AGENT_STATUSES[item.status].class" class="gl-mr-3">
            <gl-icon :name="$options.AGENT_STATUSES[item.status].icon" :size="12" /></span
          >{{ $options.AGENT_STATUSES[item.status].name }}
        </span>
        <gl-tooltip
          v-if="item.status === 'active'"
          :target="`connection-status-${item.name}`"
          placement="right"
        >
          <gl-sprintf :message="$options.AGENT_STATUSES[item.status].tooltip.title"
            ><template #timeAgo>{{ timeFormatted(item.lastContact) }}</template>
          </gl-sprintf>
        </gl-tooltip>
        <gl-popover
          v-else
          :target="`connection-status-${item.name}`"
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
            {{ s__('ClusterAgents|For more troubleshooting information go to') }}
            <gl-link :href="$options.TROUBLESHOOTING_LINK" target="_blank" class="gl-font-sm">
              {{ $options.TROUBLESHOOTING_LINK }}</gl-link
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
          <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
          <gl-link v-if="item.configFolder" :href="item.configFolder.webPath">
            .gitlab/agents/{{ item.name }}
          </gl-link>

          <span v-else>.gitlab/agents/{{ item.name }}</span>
          <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
        </span>
      </template>
    </gl-table>
  </div>
</template>
