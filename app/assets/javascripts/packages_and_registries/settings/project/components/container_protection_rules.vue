<script>
import {
  GlAlert,
  GlButton,
  GlCard,
  GlKeysetPagination,
  GlLoadingIcon,
  GlModal,
  GlModalDirective,
  GlTable,
} from '@gitlab/ui';
import protectionRulesQuery from '~/packages_and_registries/settings/project/graphql/queries/get_container_protection_rules.query.graphql';
import SettingsBlock from '~/packages_and_registries/shared/components/settings_block.vue';
import ContainerProtectionRuleForm from '~/packages_and_registries/settings/project/components/container_protection_rule_form.vue';
import deleteContainerProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/delete_container_protection_rule.mutation.graphql';
import { s__, __ } from '~/locale';

const PAGINATION_DEFAULT_PER_PAGE = 10;

const I18N_MINIMUM_ACCESS_LEVEL_FOR_PUSH = s__('ContainerRegistry|Minimum access level for push');
const I18N_MINIMUM_ACCESS_LEVEL_FOR_DELETE = s__(
  'ContainerRegistry|Minimum access level for delete',
);

const ACCESS_LEVEL_GRAPHQL_VALUE_TO_LABEL = {
  MAINTAINER: __('Maintainer'),
  OWNER: __('Owner'),
  ADMIN: __('Admin'),
};

export default {
  components: {
    ContainerProtectionRuleForm,
    GlAlert,
    GlButton,
    GlCard,
    GlKeysetPagination,
    GlLoadingIcon,
    GlModal,
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
      'ContainerRegistry|When a container is protected then only certain user roles are able to push and delete the protected container image. This helps to avoid tampering with the container image.',
    ),
    protectionRuleDeletionConfirmModal: {
      title: s__(
        'ContainerRegistry|Are you sure you want to delete the container protection rule?',
      ),
      description: s__(
        'ContainerRegistry|Users with at least the Developer role for this project will be able to push and delete container images.',
      ),
    },
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
          id: protectionRule.id,
          minimumAccessLevelForDelete:
            ACCESS_LEVEL_GRAPHQL_VALUE_TO_LABEL[protectionRule.minimumAccessLevelForDelete],
          minimumAccessLevelForPush:
            ACCESS_LEVEL_GRAPHQL_VALUE_TO_LABEL[protectionRule.minimumAccessLevelForPush],
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
    modalActionPrimary() {
      return {
        text: __('Delete'),
        attributes: {
          variant: 'danger',
        },
      };
    },
    modalActionCancel() {
      return {
        text: __('Cancel'),
      };
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
    isProtectionRuleMinimumAccessLevelForPushFormSelectDisabled(item) {
      return this.isProtectionRuleMutationInProgress(item);
    },
    isProtectionRuleDeleteButtonDisabled(item) {
      return this.isProtectionRuleMutationInProgress(item);
    },
    isProtectionRuleMutationInProgress(item) {
      return this.protectionRuleMutationItem === item && this.protectionRuleMutationInProgress;
    },
    deleteProtectionRule(protectionRule) {
      this.clearAlertMessage();

      this.protectionRuleMutationInProgress = true;

      return this.$apollo
        .mutate({
          mutation: deleteContainerProtectionRuleMutation,
          variables: { input: { id: protectionRule.id } },
        })
        .then(({ data }) => {
          const [errorMessage] = data?.deleteContainerRegistryProtectionRule?.errors ?? [];
          if (errorMessage) {
            this.alertErrorMessage = errorMessage;
            return;
          }
          this.refetchProtectionRules();
          this.$toast.show(s__('ContainerRegistry|Protection rule deleted.'));
        })
        .catch((e) => {
          this.alertErrorMessage = e.message;
        })
        .finally(() => {
          this.resetProtectionRuleMutation();
        });
    },
  },
  fields: [
    {
      key: 'repositoryPathPattern',
      label: s__('ContainerRegistry|Repository path pattern'),
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'minimumAccessLevelForPush',
      label: I18N_MINIMUM_ACCESS_LEVEL_FOR_PUSH,
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'minimumAccessLevelForDelete',
      label: I18N_MINIMUM_ACCESS_LEVEL_FOR_DELETE,
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'rowActions',
      label: '',
      thClass: 'gl-display-none',
      tdClass: 'gl-vertical-align-middle! gl-text-right',
    },
  ],
  modal: { id: 'delete-protection-rule-confirmation-modal' },
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

            <template #cell(rowActions)="{ item }">
              <gl-button
                v-gl-modal="$options.modal.id"
                category="secondary"
                variant="danger"
                size="small"
                :disabled="isProtectionRuleDeleteButtonDisabled(item)"
                @click="showProtectionRuleDeletionConfirmModal(item)"
                >{{ s__('ContainerRegistry|Delete rule') }}</gl-button
              >
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

      <gl-modal
        :modal-id="$options.modal.id"
        size="sm"
        :title="$options.i18n.protectionRuleDeletionConfirmModal.title"
        :action-primary="modalActionPrimary"
        :action-cancel="modalActionCancel"
        @primary="deleteProtectionRule(protectionRuleMutationItem)"
      >
        <p>{{ $options.i18n.protectionRuleDeletionConfirmModal.description }}</p>
      </gl-modal>
    </template>
  </settings-block>
</template>
