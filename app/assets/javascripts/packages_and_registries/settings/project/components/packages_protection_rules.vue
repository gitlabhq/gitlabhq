<script>
import {
  GlAlert,
  GlButton,
  GlDrawer,
  GlTable,
  GlLoadingIcon,
  GlKeysetPagination,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
  GlSprintf,
} from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import packagesProtectionRuleQuery from '~/packages_and_registries/settings/project/graphql/queries/get_packages_protection_rules.query.graphql';
import { getPackageTypeLabel } from '~/packages_and_registries/package_registry/utils';
import deletePackagesProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/delete_packages_protection_rule.mutation.graphql';
import PackagesProtectionRuleForm from '~/packages_and_registries/settings/project/components/packages_protection_rule_form.vue';
import { getAccessLevelLabel } from '~/packages_and_registries/settings/project/utils';
import { s__, __ } from '~/locale';

const PAGINATION_DEFAULT_PER_PAGE = 10;

const I18N_MINIMUM_ACCESS_LEVEL_FOR_PUSH = s__('PackageRegistry|Minimum access level for push');

export default {
  components: {
    CrudComponent,
    GlButton,
    GlAlert,
    GlDrawer,
    GlTable,
    GlLoadingIcon,
    PackagesProtectionRuleForm,
    GlKeysetPagination,
    GlModal,
    GlSprintf,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  inject: ['projectPath'],
  i18n: {
    delete: __('Delete'),
    editIconButton: __('Edit'),
    settingBlockTitle: s__('PackageRegistry|Protected packages'),
    settingBlockDescription: s__(
      'PackageRegistry|When a package is protected, only certain user roles can push, update, and delete the protected package, which helps to avoid tampering with the package.',
    ),
    createProtectionRuleText: s__('PackageRegistry|Add protection rule'),
    protectionRuleDeletionConfirmModal: {
      title: s__('PackageRegistry|Delete package protection rule?'),
      descriptionWarning: s__(
        'PackageRegistry|You are about to delete the package protection rule for %{packageNamePattern}.',
      ),
      descriptionConsequence: s__(
        'PackageRegistry|Users with at least the Developer role for this project will be able to publish, edit, and delete packages with this package name.',
      ),
    },
    minimumAccessLevelForPush: I18N_MINIMUM_ACCESS_LEVEL_FOR_PUSH,
  },
  data() {
    return {
      packageProtectionRules: [],
      packageProtectionRulesQueryPayload: { nodes: [], pageInfo: {} },
      packageProtectionRulesQueryPaginationParams: { first: PAGINATION_DEFAULT_PER_PAGE },
      protectionRuleMutationInProgress: false,
      protectionRuleMutationItem: null,
      alertErrorMessage: '',
      showDrawer: false,
    };
  },
  computed: {
    containsTableItems() {
      return this.packageProtectionRulesQueryResult.length > 0;
    },
    drawerTitle() {
      return this.protectionRuleMutationItem
        ? s__('PackageRegistry|Edit protection rule')
        : s__('PackageRegistry|Add protection rule');
    },
    tableItems() {
      return this.packageProtectionRulesQueryResult.map((packagesProtectionRule) => {
        return {
          id: packagesProtectionRule.id,
          minimumAccessLevelForPush: packagesProtectionRule.minimumAccessLevelForPush,
          packageNamePattern: packagesProtectionRule.packageNamePattern,
          packageType: packagesProtectionRule.packageType,
        };
      });
    },
    packageProtectionRulesQueryPageInfo() {
      return this.packageProtectionRulesQueryPayload.pageInfo;
    },
    packageProtectionRulesQueryResult() {
      return this.packageProtectionRulesQueryPayload.nodes;
    },
    isLoadingPackageProtectionRules() {
      return this.$apollo.queries.packageProtectionRulesQueryPayload.loading;
    },
    showTopLevelLoadingIcon() {
      return this.isLoadingPackageProtectionRules && !this.containsTableItems;
    },
    toastMessage() {
      return this.protectionRuleMutationItem
        ? s__('PackageRegistry|Package protection rule updated.')
        : s__('PackageRegistry|Package protection rule created.');
    },
  },
  apollo: {
    packageProtectionRulesQueryPayload: {
      query: packagesProtectionRuleQuery,
      context: {
        batchKey: 'PackageRegistryProjectSettings',
      },
      variables() {
        return {
          projectPath: this.projectPath,
          ...this.packageProtectionRulesQueryPaginationParams,
        };
      },
      update(data) {
        return data.project?.packagesProtectionRules ?? this.packageProtectionRulesQueryPayload;
      },
      error(e) {
        this.alertErrorMessage = e.message;
      },
    },
  },
  methods: {
    closeDrawer() {
      this.showDrawer = false;
    },
    refetchProtectionRules() {
      this.$apollo.queries.packageProtectionRulesQueryPayload.refetch();
    },
    onNextPage() {
      this.packageProtectionRulesQueryPaginationParams = {
        after: this.packageProtectionRulesQueryPageInfo.endCursor,
        first: PAGINATION_DEFAULT_PER_PAGE,
      };
    },
    onPrevPage() {
      this.packageProtectionRulesQueryPaginationParams = {
        before: this.packageProtectionRulesQueryPageInfo.startCursor,
        last: PAGINATION_DEFAULT_PER_PAGE,
      };
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
    showProtectionRuleDeletionConfirmModal(protectionRule) {
      this.protectionRuleMutationItem = protectionRule;
    },
    deleteProtectionRule(protectionRule) {
      this.clearAlertMessage();

      this.protectionRuleMutationInProgress = true;

      return this.$apollo
        .mutate({
          mutation: deletePackagesProtectionRuleMutation,
          variables: { input: { id: protectionRule.id } },
        })
        .then(({ data }) => {
          const [errorMessage] = data?.deletePackagesProtectionRule?.errors ?? [];
          if (errorMessage) {
            this.alertErrorMessage = errorMessage;
            return;
          }
          this.refetchProtectionRules();
          this.$toast.show(s__('PackageRegistry|Package protection rule deleted.'));
        })
        .catch((e) => {
          this.alertErrorMessage = e.message;
        })
        .finally(() => {
          this.resetProtectionRuleMutation();
        });
    },
    clearAlertMessage() {
      this.alertErrorMessage = '';
    },
    resetProtectionRuleMutation() {
      this.protectionRuleMutationItem = null;
      this.protectionRuleMutationInProgress = false;
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
      key: 'packageNamePattern',
      label: s__('PackageRegistry|Name pattern'),
      tdClass: '!gl-align-middle',
    },
    {
      key: 'packageType',
      label: s__('PackageRegistry|Type'),
      tdClass: '!gl-align-middle',
    },
    {
      key: 'minimumAccessLevelForPush',
      label: I18N_MINIMUM_ACCESS_LEVEL_FOR_PUSH,
      tdClass: '!gl-align-middle',
    },
    {
      key: 'rowActions',
      label: __('Actions'),
      thAlignRight: true,
      tdClass: '!gl-align-middle gl-text-right',
    },
  ],
  getAccessLevelLabel,
  getPackageTypeLabel,
  modal: { id: 'delete-package-protection-rule-confirmation-modal' },
  modalActionPrimary: {
    text: s__('PackageRegistry|Delete package protection rule'),
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
  <div data-testid="project-packages-protection-rules-settings">
    <crud-component
      ref="packagesCrud"
      :title="$options.i18n.settingBlockTitle"
      :toggle-text="$options.i18n.createProtectionRuleText"
      @showForm="openNewFormDrawer"
    >
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
          :fields="$options.fields"
          stacked="md"
          :aria-label="$options.i18n.settingBlockTitle"
          :busy="isLoadingPackageProtectionRules"
        >
          <template #table-busy>
            <gl-loading-icon size="sm" class="gl-my-5" />
          </template>

          <template #cell(packageType)="{ item }">
            <span data-testid="package-type">
              {{ $options.getPackageTypeLabel(item.packageType) }}
            </span>
          </template>

          <template #cell(minimumAccessLevelForPush)="{ item }">
            <span data-testid="minimum-access-level-push-value">
              {{ $options.getAccessLevelLabel(item.minimumAccessLevelForPush) }}
            </span>
          </template>

          <template #cell(rowActions)="{ item }">
            <div class="gl-flex gl-justify-end">
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
                :title="$options.i18n.delete"
                :aria-label="$options.i18n.delete"
                data-testid="delete-rule-btn"
                :disabled="isProtectionRuleDeleteButtonDisabled(item)"
                @click="showProtectionRuleDeletionConfirmModal(item)"
              />
            </div>
          </template>
        </gl-table>
        <p v-else class="gl-text-subtle">
          {{ s__('PackageRegistry|No packages are protected.') }}
        </p>
        <gl-drawer :z-index="1039" :open="showDrawer" @close="closeDrawer">
          <template #title>
            <h2 class="gl-my-0 gl-text-size-h2 gl-leading-24">
              {{ drawerTitle }}
            </h2>
          </template>
          <template #default>
            <packages-protection-rule-form
              :rule="protectionRuleMutationItem"
              @cancel="closeDrawer"
              @submit="handleSubmit"
            />
          </template>
        </gl-drawer>
      </template>

      <template #pagination>
        <gl-keyset-pagination
          v-bind="packageProtectionRulesQueryPageInfo"
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
          <template #packageNamePattern>
            <strong>{{ protectionRuleMutationItem.packageNamePattern }}</strong>
          </template>
        </gl-sprintf>
      </p>
      <p>{{ $options.i18n.protectionRuleDeletionConfirmModal.descriptionConsequence }}</p>
    </gl-modal>
  </div>
</template>
