<script>
import {
  GlAlert,
  GlButton,
  GlCard,
  GlKeysetPagination,
  GlLoadingIcon,
  GlModalDirective,
  GlTable,
} from '@gitlab/ui';
import protectionRulesQuery from '~/packages_and_registries/settings/project/graphql/queries/get_container_protection_rules.query.graphql';
import SettingsBlock from '~/packages_and_registries/shared/components/settings_block.vue';
import ContainerProtectionRuleForm from '~/packages_and_registries/settings/project/components/container_protection_rule_form.vue';
import { s__, __ } from '~/locale';

const PAGINATION_DEFAULT_PER_PAGE = 10;

const I18N_PUSH_PROTECTED_UP_TO_ACCESS_LEVEL = s__(
  'ContainerRegistry|Push protected up to access level',
);
const I18N_DELETE_PROTECTED_UP_TO_ACCESS_LEVEL = s__(
  'ContainerRegistry|Delete protected up to access level',
);

const ACCESS_LEVEL_GRAPHQL_VALUE_TO_LABEL = {
  DEVELOPER: __('Developer'),
  MAINTAINER: __('Maintainer'),
  OWNER: __('Owner'),
};

export default {
  components: {
    ContainerProtectionRuleForm,
    GlAlert,
    GlButton,
    GlCard,
    GlKeysetPagination,
    GlLoadingIcon,
    GlTable,
    SettingsBlock,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: ['projectPath'],
  i18n: {
    settingBlockTitle: s__('ContainerRegistry|Protected containers'),
    settingBlockDescription: s__(
      'ContainerRegistry|When a container is protected then only certain user roles are able to update and delete the protected container. This helps to avoid tampering with the container.',
    ),
  },
  apollo: {
    protectionRulesQueryPayload: {
      query: protectionRulesQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          ...this.protectionRulesQueryPaginationParams,
        };
      },
      update(data) {
        return data.project?.containerRegistryProtectionRules ?? this.protectionRulesQueryPayload;
      },
      error(e) {
        this.alertErrorMessage = e.message;
      },
    },
  },
  data() {
    return {
      protectionRules: [],
      protectionRuleFormVisibility: false,
      protectionRulesQueryPayload: { nodes: [], pageInfo: {} },
      protectionRulesQueryPaginationParams: { first: PAGINATION_DEFAULT_PER_PAGE },
      protectionRuleMutationInProgress: false,
      protectionRuleMutationItem: null,
      alertErrorMessage: '',
    };
  },
  computed: {
    tableItems() {
      return this.protectionRulesQueryResult.map((protectionRule) => {
        return {
          deleteProtectedUpToAccessLevel:
            ACCESS_LEVEL_GRAPHQL_VALUE_TO_LABEL[protectionRule.deleteProtectedUpToAccessLevel],
          pushProtectedUpToAccessLevel:
            ACCESS_LEVEL_GRAPHQL_VALUE_TO_LABEL[protectionRule.pushProtectedUpToAccessLevel],
          repositoryPathPattern: protectionRule.repositoryPathPattern,
        };
      });
    },
    protectionRulesQueryPageInfo() {
      return this.protectionRulesQueryPayload.pageInfo;
    },
    protectionRulesQueryResult() {
      return this.protectionRulesQueryPayload.nodes;
    },
    isLoadingprotectionRules() {
      return this.$apollo.queries.protectionRulesQueryPayload.loading;
    },
    shouldShowPagination() {
      return (
        this.protectionRulesQueryPageInfo.hasPreviousPage ||
        this.protectionRulesQueryPageInfo.hasNextPage
      );
    },
    isAddProtectionRuleButtonDisabled() {
      return this.protectionRuleFormVisibility;
    },
  },
  methods: {
    showProtectionRuleForm() {
      this.protectionRuleFormVisibility = true;
    },
    hideProtectionRuleForm() {
      this.protectionRuleFormVisibility = false;
    },
    refetchProtectionRules() {
      this.$apollo.queries.protectionRulesQueryPayload.refetch();
      this.hideProtectionRuleForm();
    },
    onNextPage() {
      this.protectionRulesQueryPaginationParams = {
        after: this.protectionRulesQueryPageInfo.endCursor,
        first: PAGINATION_DEFAULT_PER_PAGE,
      };
    },
    onPrevPage() {
      this.protectionRulesQueryPaginationParams = {
        before: this.protectionRulesQueryPageInfo.startCursor,
        last: PAGINATION_DEFAULT_PER_PAGE,
      };
    },
    showProtectionRuleDeletionConfirmModal(protectionRule) {
      this.protectionRuleMutationItem = protectionRule;
    },
    clearAlertMessage() {
      this.alertErrorMessage = '';
    },
    resetProtectionRuleMutation() {
      this.protectionRuleMutationItem = null;
      this.protectionRuleMutationInProgress = false;
    },
    isProtectionRulePushProtectedUpToAccessLevelFormSelectDisabled(item) {
      return this.isProtectionRuleMutationInProgress(item);
    },
    isProtectionRuleDeleteButtonDisabled(item) {
      return this.isProtectionRuleMutationInProgress(item);
    },
    isProtectionRuleMutationInProgress(item) {
      return this.protectionRuleMutationItem === item && this.protectionRuleMutationInProgress;
    },
  },
  fields: [
    {
      key: 'repositoryPathPattern',
      label: s__('ContainerRegistry|Repository path pattern'),
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'pushProtectedUpToAccessLevel',
      label: I18N_PUSH_PROTECTED_UP_TO_ACCESS_LEVEL,
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'deleteProtectedUpToAccessLevel',
      label: I18N_DELETE_PROTECTED_UP_TO_ACCESS_LEVEL,
      tdClass: 'gl-vertical-align-middle!',
    },
  ],
};
</script>

<template>
  <settings-block>
    <template #title>{{ $options.i18n.settingBlockTitle }}</template>

    <template #description>
      {{ $options.i18n.settingBlockDescription }}
    </template>

    <template #default>
      <gl-card
        class="gl-new-card"
        header-class="gl-new-card-header"
        body-class="gl-new-card-body gl-px-0"
      >
        <template #header>
          <div class="gl-new-card-title-wrapper gl-justify-content-space-between">
            <h3 class="gl-new-card-title">{{ $options.i18n.settingBlockTitle }}</h3>
            <div class="gl-new-card-actions">
              <gl-button
                size="small"
                :disabled="isAddProtectionRuleButtonDisabled"
                @click="showProtectionRuleForm"
              >
                {{ s__('ContainerRegistry|Add protection rule') }}
              </gl-button>
            </div>
          </div>
        </template>

        <template #default>
          <container-protection-rule-form
            v-if="protectionRuleFormVisibility"
            @cancel="hideProtectionRuleForm"
            @submit="refetchProtectionRules"
          />

          <gl-alert
            v-if="alertErrorMessage"
            class="gl-mb-5"
            variant="danger"
            @dismiss="clearAlertMessage"
          >
            {{ alertErrorMessage }}
          </gl-alert>

          <gl-table
            :items="tableItems"
            :fields="$options.fields"
            show-empty
            stacked="md"
            :aria-label="$options.i18n.settingBlockTitle"
            :busy="isLoadingprotectionRules"
          >
            <template #table-busy>
              <gl-loading-icon size="sm" class="gl-my-5" />
            </template>
          </gl-table>

          <div v-if="shouldShowPagination" class="gl-display-flex gl-justify-content-center">
            <gl-keyset-pagination
              v-bind="protectionRulesQueryPageInfo"
              class="gl-mb-3"
              :prev-text="__('Previous')"
              :next-text="__('Next')"
              @prev="onPrevPage"
              @next="onNextPage"
            />
          </div>
        </template>
      </gl-card>
    </template>
  </settings-block>
</template>
