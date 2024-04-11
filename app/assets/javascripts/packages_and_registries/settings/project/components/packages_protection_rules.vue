<script>
import {
  GlAlert,
  GlButton,
  GlCard,
  GlTable,
  GlLoadingIcon,
  GlKeysetPagination,
  GlModal,
  GlModalDirective,
  GlFormSelect,
} from '@gitlab/ui';
import packagesProtectionRuleQuery from '~/packages_and_registries/settings/project/graphql/queries/get_packages_protection_rules.query.graphql';
import { getPackageTypeLabel } from '~/packages_and_registries/package_registry/utils';
import deletePackagesProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/delete_packages_protection_rule.mutation.graphql';
import updatePackagesProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/update_packages_protection_rule.mutation.graphql';
import SettingsBlock from '~/packages_and_registries/shared/components/settings_block.vue';
import PackagesProtectionRuleForm from '~/packages_and_registries/settings/project/components/packages_protection_rule_form.vue';
import { s__, __ } from '~/locale';

const PAGINATION_DEFAULT_PER_PAGE = 10;

const I18N_PUSH_PROTECTED_UP_TO_ACCESS_LEVEL = s__(
  'PackageRegistry|Push protected up to access level',
);

export default {
  components: {
    SettingsBlock,
    GlButton,
    GlCard,
    GlAlert,
    GlTable,
    GlLoadingIcon,
    PackagesProtectionRuleForm,
    GlKeysetPagination,
    GlModal,
    GlFormSelect,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: ['projectPath'],
  i18n: {
    settingBlockTitle: s__('PackageRegistry|Protected packages'),
    settingBlockDescription: s__(
      'PackageRegistry|When a package is protected then only certain user roles are able to update and delete the protected package. This helps to avoid tampering with the package.',
    ),
    protectionRuleDeletionConfirmModal: {
      title: s__('PackageRegistry|Are you sure you want to delete the package protection rule?'),
      description: s__(
        'PackageRegistry|Users with at least the Developer role for this project will be able to publish, edit, and delete packages.',
      ),
    },
    pushProtectedUpToAccessLevel: I18N_PUSH_PROTECTED_UP_TO_ACCESS_LEVEL,
  },
  data() {
    return {
      packageProtectionRules: [],
      protectionRuleFormVisibility: false,
      packageProtectionRulesQueryPayload: { nodes: [], pageInfo: {} },
      packageProtectionRulesQueryPaginationParams: { first: PAGINATION_DEFAULT_PER_PAGE },
      protectionRuleMutationInProgress: false,
      protectionRuleMutationItem: null,
      alertErrorMessage: '',
    };
  },
  computed: {
    tableItems() {
      return this.packageProtectionRulesQueryResult.map((packagesProtectionRule) => {
        return {
          id: packagesProtectionRule.id,
          pushProtectedUpToAccessLevel: packagesProtectionRule.pushProtectedUpToAccessLevel,
          col_1_package_name_pattern: packagesProtectionRule.packageNamePattern,
          col_2_package_type: getPackageTypeLabel(packagesProtectionRule.packageType),
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
    pushProtectedUpToAccessLevelOptions() {
      return [
        { value: 'DEVELOPER', text: __('Developer') },
        { value: 'MAINTAINER', text: __('Maintainer') },
        { value: 'OWNER', text: __('Owner') },
      ];
    },
  },
  apollo: {
    packageProtectionRulesQueryPayload: {
      query: packagesProtectionRuleQuery,
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
    showProtectionRuleForm() {
      this.protectionRuleFormVisibility = true;
    },
    hideProtectionRuleForm() {
      this.protectionRuleFormVisibility = false;
    },
    refetchProtectionRules() {
      this.$apollo.queries.packageProtectionRulesQueryPayload.refetch();
      this.hideProtectionRuleForm();
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
    updatePackageProtectionRule(packageProtectionRule) {
      this.clearAlertMessage();

      this.protectionRuleMutationItem = packageProtectionRule;
      this.protectionRuleMutationInProgress = true;

      return this.$apollo
        .mutate({
          mutation: updatePackagesProtectionRuleMutation,
          variables: {
            input: {
              id: packageProtectionRule.id,
              pushProtectedUpToAccessLevel: packageProtectionRule.pushProtectedUpToAccessLevel,
            },
          },
        })
        .then(({ data }) => {
          const [errorMessage] = data?.updatePackagesProtectionRule?.errors ?? [];
          if (errorMessage) {
            this.alertErrorMessage = errorMessage;
          }

          this.$toast.show(s__('PackageRegistry|Package protection rule updated.'));
        })
        .catch((error) => {
          this.alertErrorMessage = error.message;
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
      key: 'col_1_package_name_pattern',
      label: s__('PackageRegistry|Name pattern'),
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'col_2_package_type',
      label: s__('PackageRegistry|Type'),
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'col_3_push_protected_up_to_access_level',
      label: I18N_PUSH_PROTECTED_UP_TO_ACCESS_LEVEL,
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'col_4_actions',
      label: '',
      thClass: 'gl-display-none',
      tdClass: 'gl-vertical-align-middle! gl-text-right',
    },
  ],
  modal: { id: 'delete-package-protection-rule-confirmation-modal' },
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
                {{ s__('PackageRegistry|Add protection rule') }}
              </gl-button>
            </div>
          </div>
        </template>

        <template #default>
          <packages-protection-rule-form
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
            :busy="isLoadingPackageProtectionRules"
          >
            <template #table-busy>
              <gl-loading-icon size="sm" class="gl-my-5" />
            </template>

            <template #cell(col_3_push_protected_up_to_access_level)="{ item }">
              <gl-form-select
                v-model="item.pushProtectedUpToAccessLevel"
                class="gl-max-w-34"
                required
                :aria-label="$options.i18n.pushProtectedUpToAccessLevel"
                :options="pushProtectedUpToAccessLevelOptions"
                :disabled="isProtectionRulePushProtectedUpToAccessLevelFormSelectDisabled(item)"
                @change="updatePackageProtectionRule(item)"
              />
            </template>

            <template #cell(col_4_actions)="{ item }">
              <gl-button
                v-gl-modal="$options.modal.id"
                category="secondary"
                variant="danger"
                size="small"
                :disabled="isProtectionRuleDeleteButtonDisabled(item)"
                @click="showProtectionRuleDeletionConfirmModal(item)"
                >{{ s__('PackageRegistry|Delete rule') }}</gl-button
              >
            </template>
          </gl-table>

          <div class="gl-display-flex gl-justify-content-center">
            <gl-keyset-pagination
              v-bind="packageProtectionRulesQueryPageInfo"
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
