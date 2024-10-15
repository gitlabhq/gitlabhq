<script>
import {
  GlAlert,
  GlButton,
  GlFormSelect,
  GlKeysetPagination,
  GlLoadingIcon,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
  GlTable,
  GlSprintf,
} from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import protectionRulesQuery from '~/packages_and_registries/settings/project/graphql/queries/get_container_protection_rules.query.graphql';
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';
import ContainerProtectionRuleForm from '~/packages_and_registries/settings/project/components/container_protection_rule_form.vue';
import deleteContainerProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/delete_container_protection_rule.mutation.graphql';
import updateContainerRegistryProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/update_container_registry_protection_rule.mutation.graphql';
import { s__, __ } from '~/locale';

const PAGINATION_DEFAULT_PER_PAGE = 10;

const I18N_MINIMUM_ACCESS_LEVEL_FOR_PUSH = s__('ContainerRegistry|Minimum access level for push');
const I18N_MINIMUM_ACCESS_LEVEL_FOR_DELETE = s__(
  'ContainerRegistry|Minimum access level for delete',
);

export default {
  components: {
    CrudComponent,
    ContainerProtectionRuleForm,
    GlAlert,
    GlButton,
    GlFormSelect,
    GlKeysetPagination,
    GlLoadingIcon,
    GlModal,
    GlTable,
    SettingsSection,
    GlSprintf,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  inject: ['projectPath'],
  i18n: {
    settingBlockTitle: s__('ContainerRegistry|Protected containers'),
    settingBlockDescription: s__(
      'ContainerRegistry|When a container is protected, only certain user roles can push and delete the protected container image, which helps to avoid tampering with the container image.',
    ),
    protectionRuleDeletionConfirmModal: {
      title: s__('ContainerRegistry|Delete container protection rule?'),
      descriptionWarning: s__(
        'ContainerRegistry|You are about to delete the container protection rule for %{repositoryPathPattern}.',
      ),
      descriptionConsequence: s__(
        'ContainerRegistry|Users with at least the Developer role for this project will be able to push and delete container images to this repository path.',
      ),
    },
    minimumAccessLevelForPush: I18N_MINIMUM_ACCESS_LEVEL_FOR_PUSH,
    minimumAccessLevelForDelete: I18N_MINIMUM_ACCESS_LEVEL_FOR_DELETE,
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
          minimumAccessLevelForDelete: protectionRule.minimumAccessLevelForDelete,
          minimumAccessLevelForPush: protectionRule.minimumAccessLevelForPush,
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
    modalActionPrimary() {
      return {
        text: s__('ContainerRegistry|Delete container protection rule'),
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
    minimumAccessLevelOptions() {
      return [
        { value: undefined, text: __('Developer (default)') },
        { value: 'MAINTAINER', text: __('Maintainer') },
        { value: 'OWNER', text: __('Owner') },
        { value: 'ADMIN', text: __('Admin') },
      ];
    },
  },
  methods: {
    showProtectionRuleForm() {
      this.$refs.containerProtectionCrud.showForm();
    },
    hideProtectionRuleForm() {
      this.$refs.containerProtectionCrud.hideForm();
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
          this.$toast.show(s__('ContainerRegistry|Container protection rule deleted.'));
        })
        .catch((error) => {
          this.alertErrorMessage = error.message;
        })
        .finally(() => {
          this.resetProtectionRuleMutation();
        });
    },
    updateProtectionRuleMinimumAccessLevelForPush(protectionRule) {
      this.updateProtectionRule(protectionRule, {
        minimumAccessLevelForPush: protectionRule.minimumAccessLevelForPush,
      });
    },
    updateProtectionRuleMinimumAccessLevelForDelete(protectionRule) {
      this.updateProtectionRule(protectionRule, {
        minimumAccessLevelForDelete: protectionRule.minimumAccessLevelForDelete,
      });
    },
    updateProtectionRule(protectionRule, updateData) {
      this.clearAlertMessage();

      this.protectionRuleMutationItem = protectionRule;
      this.protectionRuleMutationInProgress = true;

      return this.$apollo
        .mutate({
          mutation: updateContainerRegistryProtectionRuleMutation,
          variables: {
            input: {
              id: protectionRule.id,
              ...updateData,
            },
          },
        })
        .then(({ data }) => {
          const [errorMessage] = data?.updateContainerRegistryProtectionRule?.errors ?? [];
          if (errorMessage) {
            this.alertErrorMessage = errorMessage;
            return;
          }

          this.$toast.show(s__('ContainerRegistry|Container protection rule updated.'));
        })
        .catch((error) => {
          this.alertErrorMessage = error.message;
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
      tdClass: '!gl-align-middle',
    },
    {
      key: 'minimumAccessLevelForPush',
      label: I18N_MINIMUM_ACCESS_LEVEL_FOR_PUSH,
      tdClass: '!gl-align-middle',
    },
    {
      key: 'minimumAccessLevelForDelete',
      label: I18N_MINIMUM_ACCESS_LEVEL_FOR_DELETE,
      tdClass: '!gl-align-middle',
    },
    {
      key: 'rowActions',
      label: __('Actions'),
      thAlignRight: true,
      tdClass: '!gl-align-middle gl-text-right',
    },
  ],
  modal: { id: 'delete-protection-rule-confirmation-modal' },
};
</script>

<template>
  <settings-section
    :heading="$options.i18n.settingBlockTitle"
    :description="$options.i18n.settingBlockDescription"
  >
    <template #default>
      <crud-component
        ref="containerProtectionCrud"
        :title="$options.i18n.settingBlockTitle"
        :toggle-text="s__('ContainerRegistry|Add protection rule')"
      >
        <template #form>
          <container-protection-rule-form
            @cancel="hideProtectionRuleForm"
            @submit="refetchProtectionRules"
          />
        </template>

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

          <template #cell(minimumAccessLevelForPush)="{ item }">
            <gl-form-select
              v-model="item.minimumAccessLevelForPush"
              class="gl-max-w-34"
              required
              :aria-label="$options.i18n.minimumAccessLevelForPush"
              :options="minimumAccessLevelOptions"
              :disabled="isProtectionRuleMinimumAccessLevelForPushFormSelectDisabled(item)"
              @change="updateProtectionRuleMinimumAccessLevelForPush(item)"
            />
          </template>

          <template #cell(minimumAccessLevelForDelete)="{ item }">
            <gl-form-select
              v-model="item.minimumAccessLevelForDelete"
              class="gl-max-w-34"
              required
              :aria-label="$options.i18n.minimumAccessLevelForDelete"
              :options="minimumAccessLevelOptions"
              :disabled="isProtectionRuleMinimumAccessLevelForPushFormSelectDisabled(item)"
              @change="updateProtectionRuleMinimumAccessLevelForDelete(item)"
            />
          </template>

          <template #cell(rowActions)="{ item }">
            <gl-button
              v-gl-tooltip
              v-gl-modal="$options.modal.id"
              category="tertiary"
              icon="remove"
              :title="__('Delete')"
              :aria-label="__('Delete')"
              :disabled="isProtectionRuleDeleteButtonDisabled(item)"
              @click="showProtectionRuleDeletionConfirmModal(item)"
            />
          </template>
        </gl-table>

        <template v-if="shouldShowPagination" #pagination>
          <gl-keyset-pagination
            v-bind="protectionRulesQueryPageInfo"
            class="gl-mb-3"
            @prev="onPrevPage"
            @next="onNextPage"
          />
        </template>
      </crud-component>

      <gl-modal
        v-if="protectionRuleMutationItem"
        :modal-id="$options.modal.id"
        size="sm"
        :title="$options.i18n.protectionRuleDeletionConfirmModal.title"
        :action-primary="modalActionPrimary"
        :action-cancel="modalActionCancel"
        @primary="deleteProtectionRule(protectionRuleMutationItem)"
      >
        <p>
          <gl-sprintf
            :message="$options.i18n.protectionRuleDeletionConfirmModal.descriptionWarning"
          >
            <template #repositoryPathPattern>
              <strong>{{ protectionRuleMutationItem.repositoryPathPattern }}</strong>
            </template>
          </gl-sprintf>
        </p>
        <p>{{ $options.i18n.protectionRuleDeletionConfirmModal.descriptionConsequence }}</p>
      </gl-modal>
    </template>
  </settings-section>
</template>
