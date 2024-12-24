<script>
import { GlAlert, GlBadge, GlLoadingIcon, GlSprintf, GlTableLite } from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import getContainerProtectionTagRulesQuery from '~/packages_and_registries/settings/project/graphql/queries/get_container_protection_tag_rules.query.graphql';
import { __, s__ } from '~/locale';

const MAX_LIMIT = 5;
const I18N_MINIMUM_ACCESS_LEVEL_TO_PUSH = s__('ContainerRegistry|Minimum access level to push');
const I18N_MINIMUM_ACCESS_LEVEL_TO_DELETE = s__('ContainerRegistry|Minimum access level to delete');

export const MinimumAccessLevelOptions = {
  MAINTAINER: __('Maintainer'),
  OWNER: __('Owner'),
  ADMIN: __('Admin'),
};

export default {
  components: {
    CrudComponent,
    GlAlert,
    GlBadge,
    GlLoadingIcon,
    GlSprintf,
    GlTableLite,
  },
  inject: ['projectPath'],
  apollo: {
    protectionRulesQueryPayload: {
      query: getContainerProtectionTagRulesQuery,
      context: {
        batchKey: 'ContainerRegistryProjectSettings',
      },
      variables() {
        return {
          projectPath: this.projectPath,
          ...this.protectionRulesQueryPaginationParams,
        };
      },
      update(data) {
        return data.project?.containerProtectionTagRules ?? this.protectionRulesQueryPayload;
      },
      error(e) {
        this.alertErrorMessage = e.message;
      },
    },
  },
  data() {
    return {
      alertErrorMessage: '',
      protectionRulesQueryPayload: { nodes: [], pageInfo: {} },
      protectionRulesQueryPaginationParams: { first: MAX_LIMIT },
    };
  },
  computed: {
    containsTableItems() {
      return this.protectionRulesQueryResult.length > 0;
    },
    isLoading() {
      return this.$apollo.queries.protectionRulesQueryPayload.loading;
    },
    protectionRulesQueryResult() {
      return this.protectionRulesQueryPayload.nodes;
    },
    tableItems() {
      return this.protectionRulesQueryResult.map((protectionRule) => {
        return {
          id: protectionRule.id,
          minimumAccessLevelForPush:
            MinimumAccessLevelOptions[protectionRule.minimumAccessLevelForPush],
          minimumAccessLevelForDelete:
            MinimumAccessLevelOptions[protectionRule.minimumAccessLevelForDelete],
          tagNamePattern: protectionRule.tagNamePattern,
        };
      });
    },
  },
  methods: {
    clearAlertMessage() {
      this.alertErrorMessage = '';
    },
  },
  fields: [
    {
      key: 'tagNamePattern',
      label: s__('ContainerRegistry|Tag pattern'),
      tdClass: '!gl-align-middle',
    },
    {
      key: 'minimumAccessLevelForPush',
      label: I18N_MINIMUM_ACCESS_LEVEL_TO_PUSH,
      tdClass: '!gl-align-middle',
    },
    {
      key: 'minimumAccessLevelForDelete',
      label: I18N_MINIMUM_ACCESS_LEVEL_TO_DELETE,
      tdClass: '!gl-align-middle',
    },
  ],
  i18n: {
    title: s__('ContainerRegistry|Protected container image tags'),
  },
  MAX_LIMIT,
};
</script>

<template>
  <crud-component :title="$options.i18n.title">
    <template v-if="containsTableItems" #count>
      <gl-badge>
        <gl-sprintf :message="s__('ContainerRegistry|%{count} of %{max}')">
          <template #count>
            {{ protectionRulesQueryResult.length }}
          </template>
          <template #max>
            {{ $options.MAX_LIMIT }}
          </template>
        </gl-sprintf>
      </gl-badge>
    </template>
    <template #default>
      <p
        class="gl-pb-0 gl-text-subtle"
        :class="{ 'gl-px-5 gl-pt-4': containsTableItems }"
        data-testid="description"
      >
        {{
          s__(
            'ContainerRegistry|When a container image tag is protected, only certain user roles can create, update, and delete the protected tag, which helps to prevent unauthorized changes. You can add upto 5 protection rules per project.',
          )
        }}
      </p>

      <gl-alert
        v-if="alertErrorMessage"
        class="gl-mb-5"
        variant="danger"
        @dismiss="clearAlertMessage"
      >
        {{ alertErrorMessage }}
      </gl-alert>

      <gl-loading-icon v-if="isLoading" size="sm" class="gl-my-5" />
      <gl-table-lite
        v-else-if="containsTableItems"
        class="gl-border-t-1 gl-border-t-gray-100 gl-border-t-solid"
        :aria-label="$options.i18n.title"
        :fields="$options.fields"
        :items="tableItems"
        stacked="md"
      />
      <p v-else data-testid="empty-text" class="gl-text-subtle">
        {{ s__('ContainerRegistry|No container image tags are protected.') }}
      </p>
    </template>
  </crud-component>
</template>
