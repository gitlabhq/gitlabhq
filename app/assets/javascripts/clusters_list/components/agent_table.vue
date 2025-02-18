<script>
import {
  GlLink,
  GlTable,
  GlIcon,
  GlSprintf,
  GlTooltip,
  GlTooltipDirective,
  GlPopover,
  GlBadge,
  GlPagination,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlModalDirective,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import { MAX_LIST_COUNT, AGENT_STATUSES, I18N_AGENT_TABLE, CONNECT_MODAL_ID } from '../constants';
import { getAgentConfigPath } from '../clusters_util';
import DeleteAgentButton from './delete_agent_button.vue';
import ConnectToAgentModal from './connect_to_agent_modal.vue';

export default {
  i18n: {
    ...I18N_AGENT_TABLE,
    connectActionText: s__('ClusterAgents|Connect to %{agentName}'),
    deleteActionText: s__('ClusterAgents|Delete agent'),
    actions: __('Actions'),
    receptiveAgentTooltip: s__(
      'ClusterAgents|GitLab will establish the connection to this agent. A URL configuration is required.',
    ),
  },
  components: {
    GlLink,
    GlTable,
    GlIcon,
    GlSprintf,
    GlTooltip,
    GlPopover,
    GlBadge,
    GlPagination,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    TimeAgoTooltip,
    DeleteAgentButton,
    ConnectToAgentModal,
    HelpIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModalDirective,
  },
  mixins: [timeagoMixin],
  AGENT_STATUSES,
  troubleshootingLink: helpPagePath('user/clusters/agent/troubleshooting'),
  versionUpdateLink: helpPagePath('user/clusters/agent/install/_index', {
    anchor: 'update-the-agent-version',
  }),
  configHelpLink: helpPagePath('user/clusters/agent/install/_index', {
    anchor: 'create-an-agent-configuration-file',
  }),
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
  data() {
    return {
      currentPage: 1,
      limit: this.maxAgents ?? MAX_LIST_COUNT,
      selectedAgent: null,
    };
  },
  computed: {
    fields() {
      const tdClass = '!gl-pt-3 !gl-pb-4 !gl-align-middle';
      const thClass = '!gl-border-t-0';
      return [
        {
          key: 'name',
          label: this.$options.i18n.nameLabel,
          isRowHeader: true,
          tdClass,
          thClass,
        },
        {
          key: 'status',
          label: this.$options.i18n.statusLabel,
          tdClass,
          thClass,
        },
        {
          key: 'lastContact',
          label: this.$options.i18n.lastContactLabel,
          tdClass,
          thClass,
        },
        {
          key: 'version',
          label: this.$options.i18n.versionLabel,
          tdClass,
          thClass,
        },
        {
          key: 'agentID',
          label: this.$options.i18n.agentIdLabel,
          tdClass,
          thClass,
        },
        {
          key: 'configuration',
          label: this.$options.i18n.configurationLabel,
          tdClass,
          thClass,
        },
        {
          key: 'options',
          label: '',
          tdClass,
          thClass,
        },
      ];
    },
    agentsList() {
      if (!this.agents.length) {
        return [];
      }

      return this.agents.map((agent) => {
        const { versions, warnings } = this.getAgentVersions(agent);
        return { ...agent, versions, warnings };
      });
    },
    showPagination() {
      return !this.maxAgents && this.agents.length > this.limit;
    },
    prevPage() {
      return Math.max(this.currentPage - 1, 0);
    },
    nextPage() {
      const nextPage = this.currentPage + 1;
      return nextPage > Math.ceil(this.agents.length / this.limit) ? null : nextPage;
    },
    isUserAccessConfigured() {
      return Boolean(this.selectedAgent?.userAccessAuthorizations);
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
      const versions = [];
      const warnings = [];

      agentConnections.forEach((connection) => {
        const version = connection.metadata.version?.replace('v', '');
        if (version && !versions.includes(version)) {
          versions.push(version);
        }

        connection.warnings?.forEach((warning) => {
          const message = warning?.version?.message;
          if (message && !warnings.includes(message)) {
            warnings.push(message);
          }
        });
      });

      return {
        versions: versions.sort((a, b) => a.localeCompare(b)),
        warnings,
      };
    },
    getAgentVersionString(agent) {
      return agent.versions[0] || '';
    },
    isVersionMismatch(agent) {
      return agent.versions.length > 1;
    },
    hasWarnings(agent) {
      return agent.warnings.length > 0;
    },
    getVersionPopoverTitle(agent) {
      if (this.isVersionMismatch(agent) && this.hasWarnings(agent)) {
        return this.$options.i18n.versionWarningsMismatchTitle;
      }
      if (this.isVersionMismatch(agent)) {
        return this.$options.i18n.versionMismatchTitle;
      }
      if (this.hasWarnings(agent)) {
        return this.$options.i18n.versionWarningsTitle;
      }

      return null;
    },

    getActions(item) {
      const connectAction = {
        text: sprintf(this.$options.i18n.connectActionText, { agentName: item.name }),
        name: 'connect-agent',
        modalId: CONNECT_MODAL_ID,
        action: () => {
          this.selectedAgent = item;
        },
      };
      const deleteAction = {
        text: this.$options.i18n.deleteActionText,
        name: 'delete-agent',
        action: () => {
          this.selectedAgent = item;
        },
      };

      const actions = [connectAction];
      if (!item.isShared) {
        actions.push(deleteAction);
      }

      return actions;
    },
  },
};
</script>

<template>
  <div>
    <gl-table
      :items="agentsList"
      :fields="fields"
      :per-page="limit"
      :current-page="currentPage"
      stacked="md"
      class="!gl-mb-4"
      data-testid="cluster-agent-list-table"
    >
      <template #cell(name)="{ item }">
        <div
          class="gl-flex gl-flex-wrap gl-justify-end gl-gap-3 gl-font-normal md:gl-justify-start"
        >
          <gl-link :href="item.webPath" data-testid="cluster-agent-name-link">{{
            item.name
          }}</gl-link
          ><gl-badge v-if="item.isShared">{{ $options.i18n.sharedBadgeText }}</gl-badge>
          <gl-badge
            v-if="item.isReceptive"
            v-gl-tooltip
            :title="$options.i18n.receptiveAgentTooltip"
            :aria-label="$options.i18n.receptiveAgentTooltip"
            data-testid="cluster-agent-is-receptive"
            >{{ $options.i18n.receptiveBadgeText }}</gl-badge
          >
        </div>
      </template>

      <template #cell(status)="{ item }">
        <span
          :id="getStatusCellId(item)"
          class="md:gl-pr-5"
          data-testid="cluster-agent-connection-status"
        >
          <span :class="$options.AGENT_STATUSES[item.status].class" class="gl-mr-3">
            <gl-icon :name="$options.AGENT_STATUSES[item.status].icon" :size="16" /></span
          >{{ $options.AGENT_STATUSES[item.status].name }}
        </span>
        <gl-tooltip
          v-if="item.status === 'active'"
          :target="getStatusCellId(item)"
          placement="right"
        >
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
            <gl-link :href="$options.troubleshootingLink" target="_blank" class="gl-text-sm">
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
            v-if="isVersionMismatch(item) || hasWarnings(item)"
            name="warning"
            class="gl-ml-2"
            variant="warning"
          />
        </span>

        <gl-popover
          v-if="isVersionMismatch(item) || hasWarnings(item)"
          :target="getVersionCellId(item)"
          :title="getVersionPopoverTitle(item)"
          :data-testid="getPopoverTestId(item)"
          placement="right"
          container="viewport"
        >
          <p v-if="isVersionMismatch(item)" class="gl-mb-0">
            {{ $options.i18n.versionMismatchText }}
          </p>
          <div v-if="hasWarnings(item)">
            <p v-for="(warning, index) of item.warnings" :key="index" class="gl-mb-0">
              {{ warning }}
            </p>
            <gl-link :href="$options.versionUpdateLink" class="gl-text-sm">
              {{ $options.i18n.viewDocsText }}</gl-link
            >
          </div>
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

          <span v-else-if="item.isShared">
            {{ $options.i18n.externalConfigText }}
          </span>

          <span v-else
            >{{ $options.i18n.defaultConfigText }}
            <gl-link
              v-gl-tooltip
              :href="$options.configHelpLink"
              :title="$options.i18n.defaultConfigTooltip"
              :aria-label="$options.i18n.defaultConfigTooltip"
              class="gl-align-middle"
              ><help-icon /></gl-link
          ></span>
        </span>
      </template>

      <template #cell(options)="{ item }">
        <gl-disclosure-dropdown
          :toggle-text="$options.i18n.actions"
          text-sr-only
          category="tertiary"
          no-caret
          icon="ellipsis_v"
        >
          <template v-for="action in getActions(item)">
            <delete-agent-button
              v-if="action.name === 'delete-agent'"
              :key="action.name"
              :agent="item"
              :default-branch-name="defaultBranchName"
            />
            <gl-disclosure-dropdown-item
              v-else
              :key="action.name"
              v-gl-modal-directive="action.modalId"
              @action="action.action"
            >
              <template #list-item>
                {{ action.text }}
              </template>
            </gl-disclosure-dropdown-item>
          </template>
        </gl-disclosure-dropdown>
      </template>
    </gl-table>

    <gl-pagination
      v-if="showPagination"
      v-model="currentPage"
      :prev-page="prevPage"
      :next-page="nextPage"
      align="center"
      class="gl-mt-5"
    />

    <connect-to-agent-modal
      v-if="selectedAgent"
      :agent-id="selectedAgent.id"
      :project-path="selectedAgent.project.fullPath"
      :is-configured="isUserAccessConfigured"
    />
  </div>
</template>
