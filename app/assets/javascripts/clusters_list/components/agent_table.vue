<script>
import {
  GlLink,
  GlTable,
  GlIcon,
  GlSprintf,
  GlTooltip,
  GlTooltipDirective,
  GlPopover,
} from '@gitlab/ui';
import semverLt from 'semver/functions/lt';
import semverInc from 'semver/functions/inc';
import semverPrerelease from 'semver/functions/prerelease';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
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
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  AGENT_STATUSES,
  troubleshootingLink: helpPagePath('user/clusters/agent/troubleshooting'),
  versionUpdateLink: helpPagePath('user/clusters/agent/install/index', {
    anchor: 'update-the-agent-version',
  }),
  configHelpLink: helpPagePath('user/clusters/agent/install/index', {
    anchor: 'create-an-agent-configuration-file',
  }),
  inject: ['gitlabVersion', 'kasVersion'],
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
      const tdClass = 'gl-pt-3! gl-pb-4! gl-vertical-align-middle!';
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
          key: 'agentID',
          label: this.$options.i18n.agentIdLabel,
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
    serverVersion() {
      return this.kasVersion || this.gitlabVersion;
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
    getAgentId(item) {
      return getIdFromGraphQLId(item.id);
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
    // isVersionOutdated determines if the agent version is outdated compared to the KAS / GitLab version
    // using the following heuristics:
    // - KAS Version is used as *server* version if available, otherwise the GitLab version is used.
    // - returns `outdated` if the agent has a different major version than the server
    // - returns `outdated` if the agents minor version is at least two proper versions older than the server
    //   - *proper* -> not a prerelease version. Meaning that server prereleases (with `-rcN`) suffix are counted as the previous minor version
    //
    // Note that it does NOT support if the agent is newer than the server version.
    isVersionOutdated(agent) {
      if (!agent.versions.length) return false;

      const agentVersion = this.getAgentVersionString(agent);
      let allowableAgentVersion = semverInc(agentVersion, 'minor');

      const isServerPrerelease = Boolean(semverPrerelease(this.serverVersion));
      if (isServerPrerelease) {
        allowableAgentVersion = semverInc(allowableAgentVersion, 'minor');
      }

      return semverLt(allowableAgentVersion, this.serverVersion);
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
          <gl-icon :name="$options.AGENT_STATUSES[item.status].icon" :size="16" /></span
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
              <template #version>{{ serverVersion }}</template>
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
            <template #version>{{ serverVersion }}</template>
          </gl-sprintf>
          <gl-link :href="$options.versionUpdateLink" class="gl-font-sm">
            {{ $options.i18n.viewDocsText }}</gl-link
          >
        </p>
      </gl-popover>
    </template>

    <template #cell(agentID)="{ item }">
      <span data-testid="cluster-agent-id">
        {{ getAgentId(item) }}
      </span>
    </template>

    <template #cell(configuration)="{ item }">
      <span data-testid="cluster-agent-configuration-link">
        <gl-link v-if="item.configFolder" :href="item.configFolder.webPath">
          {{ getAgentConfigPath(item.name) }}
        </gl-link>

        <span v-else
          >{{ $options.i18n.defaultConfigText }}
          <gl-link
            v-gl-tooltip
            :href="$options.configHelpLink"
            :title="$options.i18n.defaultConfigTooltip"
            :aria-label="$options.i18n.defaultConfigTooltip"
            class="gl-vertical-align-middle"
            ><gl-icon name="question-o" :size="14" /></gl-link
        ></span>
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
