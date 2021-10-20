<script>
import { GlEmptyState, GlLink, GlTable, GlTooltip, GlTruncate } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    GlEmptyState,
    GlLink,
    GlTable,
    GlTooltip,
    GlTruncate,
    TimeAgoTooltip,
  },
  i18n: {
    createdBy: s__('ClusterAgents|Created by'),
    createToken: s__('ClusterAgents|You will need to create a token to connect to your agent'),
    dateCreated: s__('ClusterAgents|Date created'),
    description: s__('ClusterAgents|Description'),
    lastUsed: s__('ClusterAgents|Last contact'),
    learnMore: s__('ClusterAgents|Learn how to create an agent access token'),
    name: s__('ClusterAgents|Name'),
    neverUsed: s__('ClusterAgents|Never'),
    noTokens: s__('ClusterAgents|This agent has no tokens'),
    unknownUser: s__('ClusterAgents|Unknown user'),
  },
  props: {
    tokens: {
      required: true,
      type: Array,
    },
  },
  computed: {
    fields() {
      return [
        {
          key: 'name',
          label: this.$options.i18n.name,
          tdAttr: { 'data-testid': 'agent-token-name' },
        },
        {
          key: 'lastUsed',
          label: this.$options.i18n.lastUsed,
          tdAttr: { 'data-testid': 'agent-token-used' },
        },
        {
          key: 'createdAt',
          label: this.$options.i18n.dateCreated,
          tdAttr: { 'data-testid': 'agent-token-created-time' },
        },
        {
          key: 'createdBy',
          label: this.$options.i18n.createdBy,
          tdAttr: { 'data-testid': 'agent-token-created-user' },
        },
        {
          key: 'description',
          label: this.$options.i18n.description,
          tdAttr: { 'data-testid': 'agent-token-description' },
        },
      ];
    },
    learnMoreUrl() {
      return helpPagePath('user/clusters/agent/index.md', {
        anchor: 'create-an-agent-record-in-gitlab',
      });
    },
  },
  methods: {
    createdByName(token) {
      return token?.createdByUser?.name || this.$options.i18n.unknownUser;
    },
  },
};
</script>

<template>
  <div v-if="tokens.length">
    <div class="gl-text-right gl-my-5">
      <gl-link target="_blank" :href="learnMoreUrl">
        {{ $options.i18n.learnMore }}
      </gl-link>
    </div>

    <gl-table :items="tokens" :fields="fields" fixed stacked="md">
      <template #cell(lastUsed)="{ item }">
        <time-ago-tooltip v-if="item.lastUsedAt" :time="item.lastUsedAt" />
        <span v-else>{{ $options.i18n.neverUsed }}</span>
      </template>

      <template #cell(createdAt)="{ item }">
        <time-ago-tooltip :time="item.createdAt" />
      </template>

      <template #cell(createdBy)="{ item }">
        <span>{{ createdByName(item) }}</span>
      </template>

      <template #cell(description)="{ item }">
        <div v-if="item.description" :id="`tooltip-description-container-${item.id}`">
          <gl-truncate :id="`tooltip-description-${item.id}`" :text="item.description" />

          <gl-tooltip
            :container="`tooltip-description-container-${item.id}`"
            :target="`tooltip-description-${item.id}`"
            placement="top"
          >
            {{ item.description }}
          </gl-tooltip>
        </div>
      </template>
    </gl-table>
  </div>

  <gl-empty-state
    v-else
    :title="$options.i18n.noTokens"
    :primary-button-link="learnMoreUrl"
    :primary-button-text="$options.i18n.learnMore"
  />
</template>
