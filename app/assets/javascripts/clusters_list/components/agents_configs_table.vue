<script>
import { GlLink, GlButton, GlTable, GlPagination, GlAlert, GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { MAX_LIST_COUNT, MAX_CONFIGS_SHOWN } from '../constants';

export default {
  i18n: {
    registerActionText: s__('ClusterAgents|Register an agent'),
    actionsLabel: __('Actions'),
    configurationLabel: s__('ClusterAgents|Configuration'),
    maxAgentsSupport: s__('ClusterAgents|We only support 100 agents on the UI.'),
    useTerraformText: s__(
      'ClusterAgents|To manage more agents, %{linkStart}use Terraform%{linkEnd}.',
    ),
  },
  terraformDocsLink:
    'https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/cluster_agent_token',
  components: {
    GlLink,
    GlButton,
    GlTable,
    GlPagination,
    GlSprintf,
    GlAlert,
  },
  inject: ['canAddCluster'],
  props: {
    configs: {
      required: true,
      type: Array,
    },
    maxConfigs: {
      default: null,
      required: false,
      type: Number,
    },
  },
  data() {
    return {
      currentPage: 1,
      limit: this.maxConfigs ?? MAX_LIST_COUNT,
    };
  },
  computed: {
    fields() {
      const tdClass = '!gl-pt-3 !gl-pb-4 !gl-align-middle';
      const thClass = '!gl-border-t-0';
      return [
        {
          key: 'configuration',
          label: this.$options.i18n.configurationLabel,
          isRowHeader: true,
          tdClass: `${tdClass} md:gl-w-4/5`,
          thClass,
        },
        {
          key: 'actions',
          label: this.$options.i18n.actionsLabel,
          tdClass,
          thClass,
        },
      ];
    },
    showPagination() {
      return !this.maxConfigs && this.configs.length > this.limit;
    },
    prevPage() {
      return Math.max(this.currentPage - 1, 0);
    },
    nextPage() {
      const nextPage = this.currentPage + 1;
      return nextPage > Math.ceil(this.configs.length / this.limit) ? null : nextPage;
    },
    showTerraformSuggestionAlert() {
      return this.configs.length >= MAX_LIST_COUNT;
    },
    showMaxConfigsAlert() {
      return this.configs.length >= MAX_CONFIGS_SHOWN;
    },
  },
  methods: {
    registerAgent(agent) {
      this.$emit('registerAgent', agent.name);
    },
  },
};
</script>

<template>
  <div>
    <gl-table
      :items="configs"
      :fields="fields"
      :per-page="limit"
      :current-page="currentPage"
      stacked="md"
      class="!gl-mb-4"
    >
      <template #cell(configuration)="{ item }">
        <gl-link class="gl-font-normal" :href="item.webPath">{{ item.path }}</gl-link>
      </template>

      <template #cell(actions)="{ item }">
        <gl-button v-if="canAddCluster" size="small" @click="registerAgent(item)">{{
          $options.i18n.registerActionText
        }}</gl-button>
      </template>
    </gl-table>

    <gl-alert
      v-if="showTerraformSuggestionAlert"
      :dismissible="false"
      variant="warning"
      class="gl-my-4"
    >
      <span v-if="showMaxConfigsAlert">{{ $options.i18n.maxAgentsSupport }}</span>
      <span>
        <gl-sprintf :message="$options.i18n.useTerraformText">
          <template #link="{ content }">
            <gl-link :href="$options.terraformDocsLink">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </span>
    </gl-alert>

    <gl-pagination
      v-if="showPagination"
      v-model="currentPage"
      :prev-page="prevPage"
      :next-page="nextPage"
      :total-items="configs.length"
      align="center"
      class="gl-mt-5"
    />
  </div>
</template>
