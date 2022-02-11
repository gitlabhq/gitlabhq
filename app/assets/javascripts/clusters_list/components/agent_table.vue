<script>
import { GlLink, GlTable, GlIcon, GlSprintf, GlTooltip, GlPopover } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { helpPagePath } from '~/helpers/help_page_helper';
import { AGENT_STATUSES, I18N_AGENT_TABLE } from '../constants';
import { getAgentConfigPath } from '../clusters_util';
import DeleteAgentButton from './delete_agent_button.vue';

export default {
  i18n: I18N_AGENT_TABLE,
  components: {
    GlLink,
    GlTable,
    GlIcon,
    GlSprintf,
    GlTooltip,
    GlPopover,
    TimeAgoTooltip,
    DeleteAgentButton,
  },
  mixins: [timeagoMixin],
  AGENT_STATUSES,
  troubleshootingLink: helpPagePath('user/clusters/agent/troubleshooting'),
  versionUpdateLink: helpPagePath('user/clusters/agent/install/index', {
    anchor: 'update-the-agent-version',
  }),
  inject: ['gitlabVersion'],
  props: {
    agents: {
      required: true,
      type: Array,
    },
    defaultBranchName: {
      default: '.noBranch',
      required: false,
      type: String,
    },
    maxAgents: {
      default: null,
      required: false,
      type: Number,
    },
  },
  computed: {
    fields() {
      const tdClass = 'gl-py-5!';
      return [
        {
          key: 'name',
          label: this.$options.i18n.nameLabel,
          tdClass,
        },
        {
          key: 'status',
          label: this.$options.i18n.statusLabel,
          tdClass,
        },
        {
          key: 'lastContact',
          label: this.$options.i18n.lastContactLabel,
          tdClass,
        },
        {
          key: 'version',
          label: this.$options.i18n.versionLabel,
          tdClass,
        },
        {
          key: 'configuration',
          label: this.$options.i18n.configurationLabel,
          tdClass,
        },
        {
          key: 'options',
          label: '',
          tdClass,
        },
      ];
    },
    agentsList() {
      if (!this.agents.length) {
        return [];
      }

      return this.agents.map((agent) => {
        const versions = this.getAgentVersions(agent);
        return { ...agent, versions };
      });
    },
  },
  methods: {
    getStatusCellId(item) {
      return `connection-status-${item.name}`;
    },
    getVersionCellId(item) {
      return `version-${item.name}`;
    },
    getPopoverTestId(item) {
      return `popover-${item.name}`;
    },
    getAgentConfigPath,
    getAgentVersions(agent) {
      const agentConnections = agent.connections?.nodes || [];

      const agentVersions = agentConnections.map((agentConnection) =>
        agentConnection.metadata.version.replace('v', ''),
      );

      const uniqueAgentVersions = [...new Set(agentVersions)];

      return uniqueAgentVersions.sort((a, b) => a.localeCompare(b));
    },
    getAgentVersionString(agent) {
      return agent.versions[0] || '';
    },
    isVersionMismatch(agent) {
      return agent.versions.length > 1;
    },
    isVersionOutdated(agent) {
      if (!agent.versions.length) return false;

      const [agentMajorVersion, agentMinorVersion] = this.getAgentVersionString(agent).split('.');
      const [gitlabMajorVersion, gitlabMinorVersion] = this.gitlabVersion.split('.');

      const majorVersionMismatch = agentMajorVersion !== gitlabMajorVersion;

      // We should warn user if their current GitLab and agent versions are more than 1 minor version apart:
      const minorVersionMismatch = Math.abs(agentMinorVersion - gitlabMinorVersion) > 1;

      return majorVersionMismatch || minorVersionMismatch;
    },

    getVersionPopoverTitle(agent) {
      if (this.isVersionMismatch(agent) && this.isVersionOutdated(agent)) {
        return this.$options.i18n.versionMismatchOutdatedTitle;
      } else if (this.isVersionMismatch(agent)) {
        return this.$options.i18n.versionMismatchTitle;
      } else if (this.isVersionOutdated(agent)) {
        return this.$options.i18n.versionOutdatedTitle;
      }

      return null;
    },
  },
};
</script>

<template>
  <gl-table
    :items="agentsList"
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
      <span
        :id="getStatusCellId(item)"
        class="gl-md-pr-5"
        data-testid="cluster-agent-connection-status"
      >
        <span :class="$options.AGENT_STATUSES[item.status].class" class="gl-mr-3">
          <gl-icon :name="$options.AGENT_STATUSES[item.status].icon" :size="12" /></span
        >{{ $options.AGENT_STATUSES[item.status].name }}
      </span>
      <gl-tooltip v-if="item.status === 'active'" :target="getStatusCellId(item)" placement="right">
        <gl-sprintf :message="$options.AGENT_STATUSES[item.status].tooltip.title"
          ><template #timeAgo>{{ timeFormatted(item.lastContact) }}</template>
        </gl-sprintf>
      </gl-tooltip>
      <gl-popover
        v-else
        :target="getStatusCellId(item)"
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
          <gl-link :href="$options.troubleshootingLink" target="_blank" class="gl-font-sm">
            {{ $options.i18n.troubleshootingText }}</gl-link
          >
        </p>
      </gl-popover>
    </template>

    <template #cell(lastContact)="{ item }">
      <span data-testid="cluster-agent-last-contact">
        <time-ago-tooltip v-if="item.lastContact" :time="item.lastContact" />
        <span v-else>{{ $options.i18n.neverConnectedText }}</span>
      </span>
    </template>

    <template #cell(version)="{ item }">
      <span :id="getVersionCellId(item)" data-testid="cluster-agent-version">
        {{ getAgentVersionString(item) }}

        <gl-icon
          v-if="isVersionMismatch(item) || isVersionOutdated(item)"
          name="warning"
          class="gl-text-orange-500 gl-ml-2"
        />
      </span>

      <gl-popover
        v-if="isVersionMismatch(item) || isVersionOutdated(item)"
        :target="getVersionCellId(item)"
        :title="getVersionPopoverTitle(item)"
        :data-testid="getPopoverTestId(item)"
        placement="right"
        container="viewport"
      >
        <div v-if="isVersionMismatch(item) && isVersionOutdated(item)">
          <p>{{ $options.i18n.versionMismatchText }}</p>

          <p class="gl-mb-0">
            <gl-sprintf :message="$options.i18n.versionOutdatedText">
              <template #version>{{ gitlabVersion }}</template>
            </gl-sprintf>
            <gl-link :href="$options.versionUpdateLink" class="gl-font-sm">
              {{ $options.i18n.viewDocsText }}</gl-link
            >
          </p>
        </div>
        <p v-else-if="isVersionMismatch(item)" class="gl-mb-0">
          {{ $options.i18n.versionMismatchText }}
        </p>

        <p v-else-if="isVersionOutdated(item)" class="gl-mb-0">
          <gl-sprintf :message="$options.i18n.versionOutdatedText">
            <template #version>{{ gitlabVersion }}</template>
          </gl-sprintf>
          <gl-link :href="$options.versionUpdateLink" class="gl-font-sm">
            {{ $options.i18n.viewDocsText }}</gl-link
          >
        </p>
      </gl-popover>
    </template>

    <template #cell(configuration)="{ item }">
      <span data-testid="cluster-agent-configuration-link">
        <gl-link v-if="item.configFolder" :href="item.configFolder.webPath">
          {{ getAgentConfigPath(item.name) }}
        </gl-link>

        <span v-else>{{ getAgentConfigPath(item.name) }}</span>
      </span>
    </template>

    <template #cell(options)="{ item }">
      <delete-agent-button
        :agent="item"
        :default-branch-name="defaultBranchName"
        :max-agents="maxAgents"
      />
    </template>
  </gl-table>
</template>
