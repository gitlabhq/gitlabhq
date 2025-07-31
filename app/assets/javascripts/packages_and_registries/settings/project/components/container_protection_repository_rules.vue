<script>
import {
  GlAlert,
  GlButton,
  GlKeysetPagination,
  GlLoadingIcon,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
  GlTable,
  GlSprintf,
  GlDrawer,
} from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import getContainerPotectionRepositoryRulesQuery from '~/packages_and_registries/settings/project/graphql/queries/get_container_protection_repository_rules.query.graphql';
import ContainerProtectionRepositoryRuleForm from '~/packages_and_registries/settings/project/components/container_protection_repository_rule_form.vue';
import deleteContainerProtectionRepositoryRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/delete_container_protection_repository_rule.mutation.graphql';
import { ContainerRepositoryMinimumAccessLevelText } from '~/packages_and_registries/settings/project/constants';
import { s__, __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';

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
    GlKeysetPagination,
    GlLoadingIcon,
    GlModal,
    GlTable,
    GlSprintf,
    GlDrawer,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['projectPath'],
  i18n: {
    editIconButton: __('Edit'),
    deleteIconButton: __('Delete'),
    settingBlockTitle: s__('ContainerRegistry|Protected container repositories'),
    settingBlockDescription: s__(
      'ContainerRegistry|When a container repository is protected, only users with specific roles can push and delete container images. This helps prevent unauthorized modifications.',
    ),
    deletionConfirmModal: {
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
      showDrawer: false,
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
    showTopLevelLoading() {
      return this.isLoadingprotectionRules && !this.containsTableItems;
    },
    drawerTitle() {
      return this.protectionRuleMutationItem
        ? s__('ContainerRegistry|Edit protection rule')
        : s__('ContainerRegistry|Add protection rule');
    },
    toastMessage() {
      return this.protectionRuleMutationItem
        ? s__('ContainerRegistry|Protection rule updated.')
        : s__('ContainerRegistry|Protection rule created.');
    },
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
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
    showDeletionConfirmModal(protectionRule) {
      this.protectionRuleMutationItem = protectionRule;
    },
    clearAlertMessage() {
      this.alertErrorMessage = '';
    },
    resetProtectionRuleMutation() {
      this.protectionRuleMutationItem = null;
      this.protectionRuleMutationInProgress = false;
    },
    isMinimumAccessLevelForPushDisabled(item) {
      return this.isProtectionRuleMutationInProgress(item);
    },
    isDeleteActionDisabled(item) {
      return this.isProtectionRuleMutationInProgress(item);
    },
    isProtectionRuleMutationInProgress(item) {
      return this.protectionRuleMutationItem === item && this.protectionRuleMutationInProgress;
    },
    handleSubmit() {
      this.$toast.show(this.toastMessage);
      this.closeDrawer();
      this.refetchProtectionRules();
    },
    openEditFormDrawer(item) {
      this.protectionRuleMutationItem = item;
      this.showDrawer = true;
    },
    openNewFormDrawer() {
      this.protectionRuleMutationItem = null;
      this.showDrawer = true;
    },
    closeDrawer() {
      this.showDrawer = false;
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
  minimumAccessLevelText: ContainerRepositoryMinimumAccessLevelText,
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
  DRAWER_Z_INDEX,
};
</script>

<template>
  <div data-testid="project-container-repository-protection-rules-settings">
    <crud-component
      ref="containerProtectionCrud"
      :title="$options.i18n.settingBlockTitle"
      :description="$options.i18n.settingBlockDescription"
      :is-loading="showTopLevelLoading"
      :toggle-text="s__('ContainerRegistry|Add protection rule')"
      @showForm="openNewFormDrawer"
    >
      <template #default>
        <gl-alert
          v-if="alertErrorMessage"
          class="gl-mb-5"
          variant="danger"
          @dismiss="clearAlertMessage"
        >
          {{ alertErrorMessage }}
        </gl-alert>

        <gl-table
          v-if="containsTableItems"
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
            <span data-testid="minimum-access-level-push-value">
              {{ $options.minimumAccessLevelText[item.minimumAccessLevelForPush] }}
            </span>
          </template>

          <template
            v-if="glFeatures.containerRegistryProtectedContainersDelete"
            #cell(minimumAccessLevelForDelete)="{ item }"
          >
            <span data-testid="minimum-access-level-delete-value">
              {{ $options.minimumAccessLevelText[item.minimumAccessLevelForDelete] }}
            </span>
          </template>

          <template #cell(rowActions)="{ item }">
            <gl-button
              v-gl-tooltip
              category="tertiary"
              icon="pencil"
              :title="$options.i18n.editIconButton"
              :aria-label="$options.i18n.editIconButton"
              @click="openEditFormDrawer(item)"
            />
            <gl-button
              v-gl-tooltip
              v-gl-modal="$options.modal.id"
              category="tertiary"
              icon="remove"
              :title="$options.i18n.deleteIconButton"
              :aria-label="$options.i18n.deleteIconButton"
              :disabled="isDeleteActionDisabled(item)"
              data-testid="delete-btn"
              @click="showDeletionConfirmModal(item)"
            />
          </template>
        </gl-table>

        <p v-else class="gl-mb-0 gl-text-subtle">
          {{ s__('ContainerRegistry|No container repositories are protected.') }}
        </p>

        <gl-drawer
          :z-index="$options.DRAWER_Z_INDEX"
          :header-height="getDrawerHeaderHeight"
          :open="showDrawer"
          @close="closeDrawer"
        >
          <template #title>
            <h2 class="gl-my-0 gl-text-size-h2 gl-leading-24">
              {{ drawerTitle }}
            </h2>
          </template>
          <template #default>
            <container-protection-repository-rule-form
              :rule="protectionRuleMutationItem"
              @cancel="closeDrawer"
              @submit="handleSubmit"
            />
          </template>
        </gl-drawer>
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
      :title="$options.i18n.deletionConfirmModal.title"
      :action-primary="$options.modalActionPrimary"
      :action-cancel="$options.modalActionCancel"
      @primary="deleteProtectionRule(protectionRuleMutationItem)"
    >
      <p>
        <gl-sprintf :message="$options.i18n.deletionConfirmModal.descriptionWarning">
          <template #repositoryPathPattern>
            <strong>{{ protectionRuleMutationItem.repositoryPathPattern }}</strong>
          </template>
        </gl-sprintf>
      </p>
      <p>{{ $options.i18n.deletionConfirmModal.descriptionConsequence }}</p>
    </gl-modal>
  </div>
</template>
