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
import getContainerPotectionRepositoryRulesQuery from '~/packages_and_registries/settings/project/graphql/queries/get_container_protection_repository_rules.query.graphql';
import ContainerProtectionRepositoryRuleForm from '~/packages_and_registries/settings/project/components/container_protection_repository_rule_form.vue';
import deleteContainerProtectionRepositoryRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/delete_container_protection_repository_rule.mutation.graphql';
import updateContainerRegistryProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/update_container_protection_repository_rule.mutation.graphql';
import { ContainerRepositoryMinimumAccessLevelOptions } from '~/packages_and_registries/settings/project/constants';
import { s__, __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

const PAGINATION_DEFAULT_PER_PAGE = 10;

const I18N_MINIMUM_ACCESS_LEVEL_FOR_PUSH = s__('ContainerRegistry|Minimum access level for push');
const I18N_MINIMUM_ACCESS_LEVEL_FOR_DELETE = s__(
  'ContainerRegistry|Minimum access level for delete',
);

export default {
  components: {
    CrudComponent,
    ContainerProtectionRepositoryRuleForm,
    GlAlert,
    GlButton,
    GlFormSelect,
    GlKeysetPagination,
    GlLoadingIcon,
    GlModal,
    GlTable,
    GlSprintf,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['projectPath'],
  i18n: {
    settingBlockTitle: s__('ContainerRegistry|Protected container repositories'),
    settingBlockDescription: s__(
      'ContainerRegistry|When a container repository is protected, only users with specific roles can push and delete container images. This helps prevent unauthorized modifications.',
    ),
    protectionRuleDeletionConfirmModal: {
      title: s__('ContainerRegistry|Delete container repository protection rule?'),
      descriptionWarning: s__(
        'ContainerRegistry|You are about to delete the container repository protection rule for %{repositoryPathPattern}.',
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
      query: getContainerPotectionRepositoryRulesQuery,
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
        return data.project?.containerProtectionRepositoryRules ?? this.protectionRulesQueryPayload;
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
    fields() {
      if (this.glFeatures.containerRegistryProtectedContainersDelete) {
        return this.$options.fields;
      }
      return this.$options.fields.filter((field) => field.key !== 'minimumAccessLevelForDelete');
    },
    containsTableItems() {
      return this.protectionRulesQueryResult.length > 0;
    },
    tableItems() {
      return this.protectionRulesQueryResult.map((protectionRule) => {
        return {
          id: protectionRule.id,
          minimumAccessLevelForDelete: protectionRule.minimumAccessLevelForDelete || '',
          minimumAccessLevelForPush: protectionRule.minimumAccessLevelForPush || '',
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
    showTopLevelLoadingIcon() {
      return this.isLoadingprotectionRules && !this.containsTableItems;
    },
    containerRepositoryMinimumAccessLevelOptions() {
      return this.glFeatures.containerRegistryProtectedContainersDelete
        ? this.$options.containerRepositoryMinimumAccessLevelOptions
        : this.$options.containerRepositoryMinimumAccessLevelOptions.filter((option) =>
            Boolean(option.value),
          );
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
          mutation: deleteContainerProtectionRepositoryRuleMutation,
          variables: { input: { id: protectionRule.id } },
        })
        .then(({ data }) => {
          const [errorMessage] = data?.deleteContainerProtectionRepositoryRule?.errors ?? [];
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
        minimumAccessLevelForPush: protectionRule.minimumAccessLevelForPush || null,
      });
    },
    updateProtectionRuleMinimumAccessLevelForDelete(protectionRule) {
      this.updateProtectionRule(protectionRule, {
        minimumAccessLevelForDelete: protectionRule.minimumAccessLevelForDelete || null,
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
          const [errorMessage] = data?.updateContainerProtectionRepositoryRule?.errors ?? [];
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
  containerRepositoryMinimumAccessLevelOptions: ContainerRepositoryMinimumAccessLevelOptions,
  modal: { id: 'delete-protection-rule-confirmation-modal' },
  modalActionPrimary: {
    text: s__('ContainerRegistry|Delete container protection rule'),
    attributes: {
      variant: 'danger',
    },
  },
  modalActionCancel: {
    text: __('Cancel'),
  },
};
</script>

<template>
  <div data-testid="project-container-repository-protection-rules-settings">
    <crud-component
      ref="containerProtectionCrud"
      :title="$options.i18n.settingBlockTitle"
      :toggle-text="s__('ContainerRegistry|Add protection rule')"
    >
      <template #form>
        <container-protection-repository-rule-form
          @cancel="hideProtectionRuleForm"
          @submit="refetchProtectionRules"
        />
      </template>

      <template #default>
        <p
          class="gl-pb-0 gl-text-subtle"
          :class="{ 'gl-px-5 gl-pt-4': containsTableItems }"
          data-testid="description"
        >
          {{ $options.i18n.settingBlockDescription }}
        </p>

        <gl-alert
          v-if="alertErrorMessage"
          class="gl-mb-5"
          variant="danger"
          @dismiss="clearAlertMessage"
        >
          {{ alertErrorMessage }}
        </gl-alert>

        <gl-loading-icon v-if="showTopLevelLoadingIcon" size="sm" class="gl-my-5" />
        <gl-table
          v-else-if="containsTableItems"
          class="gl-border-t-1 gl-border-t-gray-100 gl-border-t-solid"
          :items="tableItems"
          :fields="fields"
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
              :options="containerRepositoryMinimumAccessLevelOptions"
              :disabled="isProtectionRuleMinimumAccessLevelForPushFormSelectDisabled(item)"
              data-testid="minimum-access-level-for-push-select"
              @change="updateProtectionRuleMinimumAccessLevelForPush(item)"
            />
          </template>

          <template #cell(minimumAccessLevelForDelete)="{ item }">
            <gl-form-select
              v-model="item.minimumAccessLevelForDelete"
              class="gl-max-w-34"
              required
              :aria-label="$options.i18n.minimumAccessLevelForDelete"
              :options="containerRepositoryMinimumAccessLevelOptions"
              data-testid="minimum-access-level-for-delete-select"
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
              data-testid="delete-btn"
              @click="showProtectionRuleDeletionConfirmModal(item)"
            />
          </template>
        </gl-table>
        <p v-else class="gl-text-subtle">
          {{ s__('ContainerRegistry|No container repositories are protected.') }}
        </p>
      </template>

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
      :action-primary="$options.modalActionPrimary"
      :action-cancel="$options.modalActionCancel"
      @primary="deleteProtectionRule(protectionRuleMutationItem)"
    >
      <p>
        <gl-sprintf :message="$options.i18n.protectionRuleDeletionConfirmModal.descriptionWarning">
          <template #repositoryPathPattern>
            <strong>{{ protectionRuleMutationItem.repositoryPathPattern }}</strong>
          </template>
        </gl-sprintf>
      </p>
      <p>{{ $options.i18n.protectionRuleDeletionConfirmModal.descriptionConsequence }}</p>
    </gl-modal>
  </div>
</template>
