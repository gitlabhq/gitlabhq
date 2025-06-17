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
import getPackagesProtectionRuleQuery from '~/packages_and_registries/settings/project/graphql/queries/get_packages_protection_rules.query.graphql';
import { getPackageTypeLabel } from '~/packages_and_registries/package_registry/utils';
import deletePackagesProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/delete_packages_protection_rule.mutation.graphql';
import PackagesProtectionRuleForm from '~/packages_and_registries/settings/project/components/packages_protection_rule_form.vue';
import { getAccessLevelLabel } from '~/packages_and_registries/settings/project/utils';
import {
  PackagesMinimumAccessForPushLevelText,
  PackagesMinimumAccessForDeleteLevelText,
} from '~/packages_and_registries/settings/project/constants';
import { s__, __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';

const PAGINATION_DEFAULT_PER_PAGE = 10;

const I18N_MINIMUM_ACCESS_LEVEL_FOR_PUSH = s__('PackageRegistry|Minimum access level for push');
const I18N_MINIMUM_ACCESS_LEVEL_FOR_DELETE = s__('PackageRegistry|Minimum access level for delete');

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
  mixins: [glFeatureFlagsMixin()],
  inject: ['projectPath'],
  i18n: {
    delete: __('Delete'),
    editIconButton: __('Edit'),
    settingBlockTitle: s__('PackageRegistry|Protected packages'),
    settingBlockDescription: s__(
      'PackageRegistry|When a package is protected, only certain user roles can push, update, and delete the protected package, which helps to avoid tampering with the package.',
    ),
    deletionConfirmModal: {
      title: s__('PackageRegistry|Delete package protection rule?'),
      descriptionWarning: s__(
        'PackageRegistry|You are about to delete the package protection rule for %{packageNamePattern}.',
      ),
      descriptionConsequence: s__(
        'PackageRegistry|Users with at least the Developer role for this project will be able to publish, edit, and delete packages with this package name.',
      ),
    },
    minimumAccessLevelForPush: I18N_MINIMUM_ACCESS_LEVEL_FOR_PUSH,
    minimumAccessLevelForDelete: I18N_MINIMUM_ACCESS_LEVEL_FOR_DELETE,
  },
  apollo: {
    protectionRulesQueryPayload: {
      query: getPackagesProtectionRuleQuery,
      context: {
        batchKey: 'PackageRegistryProjectSettings',
      },
      variables() {
        return {
          projectPath: this.projectPath,
          ...this.protectionRulesQueryPaginationParams,
        };
      },
      update(data) {
        return data.project?.packagesProtectionRules ?? this.protectionRulesQueryPayload;
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
      mutationInProgress: false,
      mutationItem: null,
      alertErrorMessage: '',
      showDrawer: false,
    };
  },
  computed: {
    containsTableItems() {
      return this.protectionRulesQueryResult.length > 0;
    },
    drawerTitle() {
      return this.mutationItem
        ? s__('PackageRegistry|Edit protection rule')
        : s__('PackageRegistry|Add protection rule');
    },
    fields() {
      return this.glFeatures.packagesProtectedPackagesDelete
        ? this.$options.fields
        : this.$options.fields.filter((field) => field.key !== 'minimumAccessLevelForDelete');
    },
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    tableItems() {
      return this.protectionRulesQueryResult.map((protectionRule) => {
        return {
          id: protectionRule.id,
          minimumAccessLevelForDelete: protectionRule.minimumAccessLevelForDelete,
          minimumAccessLevelForPush: protectionRule.minimumAccessLevelForPush,
          packageNamePattern: protectionRule.packageNamePattern,
          packageType: protectionRule.packageType,
        };
      });
    },
    protectionRulesQueryPageInfo() {
      return this.protectionRulesQueryPayload.pageInfo;
    },
    protectionRulesQueryResult() {
      return this.protectionRulesQueryPayload.nodes;
    },
    isLoadingProtectionRules() {
      return this.$apollo.queries.protectionRulesQueryPayload.loading;
    },
    showTopLevelLoadingIcon() {
      return this.isLoadingProtectionRules && !this.containsTableItems;
    },
    toastMessage() {
      return this.mutationItem
        ? s__('PackageRegistry|Package protection rule updated.')
        : s__('PackageRegistry|Package protection rule created.');
    },
  },
  methods: {
    closeDrawer() {
      this.showDrawer = false;
    },
    refetchProtectionRules() {
      this.$apollo.queries.protectionRulesQueryPayload.refetch();
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
    handleSubmit() {
      this.$toast.show(this.toastMessage);
      this.closeDrawer();
      this.refetchProtectionRules();
    },
    openEditFormDrawer(item) {
      this.mutationItem = item;
      this.showDrawer = true;
    },
    openNewFormDrawer() {
      this.mutationItem = null;
      this.showDrawer = true;
    },
    showDeletionConfirmModal(protectionRule) {
      this.mutationItem = protectionRule;
    },
    deleteProtectionRule(protectionRule) {
      this.clearAlertMessage();

      this.mutationInProgress = true;

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
      this.mutationItem = null;
      this.mutationInProgress = false;
    },
    isDeleteButtonDisabled(item) {
      return this.isMutationInProgress(item);
    },
    isMutationInProgress(item) {
      return this.mutationItem === item && this.mutationInProgress;
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
  getAccessLevelLabel,
  getPackageTypeLabel,
  minimumAccessForPushLevelText: PackagesMinimumAccessForPushLevelText,
  minimumAccessForDeleteLevelText: PackagesMinimumAccessForDeleteLevelText,
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
  DRAWER_Z_INDEX,
};
</script>

<template>
  <div data-testid="project-packages-protection-rules-settings">
    <crud-component
      ref="packagesCrud"
      :title="$options.i18n.settingBlockTitle"
      :description="$options.i18n.settingBlockDescription"
      :toggle-text="s__('PackageRegistry|Add protection rule')"
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

        <gl-loading-icon v-if="showTopLevelLoadingIcon" size="sm" class="gl-my-5" />
        <gl-table
          v-else-if="containsTableItems"
          class="gl-border-t-1 gl-border-t-gray-100 gl-border-t-solid"
          :items="tableItems"
          :fields="fields"
          stacked="md"
          :aria-label="$options.i18n.settingBlockTitle"
          :busy="isLoadingProtectionRules"
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
              {{ $options.minimumAccessForPushLevelText[item.minimumAccessLevelForPush] }}
            </span>
          </template>

          <template
            v-if="glFeatures.packagesProtectedPackagesDelete"
            #cell(minimumAccessLevelForDelete)="{ item }"
          >
            <span data-testid="minimum-access-level-delete-value">
              {{ $options.minimumAccessForDeleteLevelText[item.minimumAccessLevelForDelete] }}
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
                :disabled="isDeleteButtonDisabled(item)"
                @click="showDeletionConfirmModal(item)"
              />
            </div>
          </template>
        </gl-table>
        <p v-else class="gl-text-subtle">
          {{ s__('PackageRegistry|No packages are protected.') }}
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
            <packages-protection-rule-form
              :rule="mutationItem"
              @cancel="closeDrawer"
              @submit="handleSubmit"
            />
          </template>
        </gl-drawer>
      </template>

      <template #pagination>
        <gl-keyset-pagination
          v-bind="protectionRulesQueryPageInfo"
          @prev="onPrevPage"
          @next="onNextPage"
        />
      </template>
    </crud-component>

    <gl-modal
      v-if="mutationItem"
      :modal-id="$options.modal.id"
      size="sm"
      :title="$options.i18n.deletionConfirmModal.title"
      :action-primary="$options.modalActionPrimary"
      :action-cancel="$options.modalActionCancel"
      @primary="deleteProtectionRule(mutationItem)"
    >
      <p>
        <gl-sprintf :message="$options.i18n.deletionConfirmModal.descriptionWarning">
          <template #packageNamePattern>
            <strong>{{ mutationItem.packageNamePattern }}</strong>
          </template>
        </gl-sprintf>
      </p>
      <p>{{ $options.i18n.deletionConfirmModal.descriptionConsequence }}</p>
    </gl-modal>
  </div>
</template>
