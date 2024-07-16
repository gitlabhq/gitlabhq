<script>
import {
  GlAlert,
  GlButton,
  GlTable,
  GlLoadingIcon,
  GlKeysetPagination,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
  GlFormSelect,
  GlSprintf,
} from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import packagesProtectionRuleQuery from '~/packages_and_registries/settings/project/graphql/queries/get_packages_protection_rules.query.graphql';
import { getPackageTypeLabel } from '~/packages_and_registries/package_registry/utils';
import deletePackagesProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/delete_packages_protection_rule.mutation.graphql';
import updatePackagesProtectionRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/update_packages_protection_rule.mutation.graphql';
import SettingsBlock from '~/packages_and_registries/shared/components/settings_block.vue';
import PackagesProtectionRuleForm from '~/packages_and_registries/settings/project/components/packages_protection_rule_form.vue';
import { s__, __ } from '~/locale';

const PAGINATION_DEFAULT_PER_PAGE = 10;

const I18N_MINIMUM_ACCESS_LEVEL_FOR_PUSH = s__('PackageRegistry|Minimum access level for push');

export default {
  components: {
    CrudComponent,
    SettingsBlock,
    GlButton,
    GlAlert,
    GlTable,
    GlLoadingIcon,
    PackagesProtectionRuleForm,
    GlKeysetPagination,
    GlModal,
    GlFormSelect,
    GlSprintf,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  inject: ['projectPath'],
  i18n: {
    settingBlockTitle: s__('PackageRegistry|Protected packages'),
    settingBlockDescription: s__(
      'PackageRegistry|When a package is protected, only certain user roles can push, update, and delete the protected package, which helps to avoid tampering with the package.',
    ),
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
          minimumAccessLevelForPush: packagesProtectionRule.minimumAccessLevelForPush,
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
        text: s__('PackageRegistry|Delete package protection rule'),
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
        { value: 'MAINTAINER', text: __('Maintainer') },
        { value: 'OWNER', text: __('Owner') },
        { value: 'ADMIN', text: s__('AdminUsers|Administrator') },
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
              minimumAccessLevelForPush: packageProtectionRule.minimumAccessLevelForPush,
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
    isProtectionRuleMinimumAccessLevelFormSelectDisabled(item) {
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
      tdClass: '!gl-align-middle',
    },
    {
      key: 'col_2_package_type',
      label: s__('PackageRegistry|Type'),
      tdClass: '!gl-align-middle',
    },
    {
      key: 'col_3_minimum_access_level_for_push',
      label: I18N_MINIMUM_ACCESS_LEVEL_FOR_PUSH,
      tdClass: '!gl-align-middle',
    },
    {
      key: 'col_4_actions',
      label: __('Actions'),
      thClass: 'gl-text-right',
      tdClass: '!gl-align-middle gl-text-right',
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
      <crud-component :title="$options.i18n.settingBlockTitle">
        <template #actions>
          <gl-button
            size="small"
            :disabled="isAddProtectionRuleButtonDisabled"
            @click="showProtectionRuleForm"
          >
            {{ s__('PackageRegistry|Add protection rule') }}
          </gl-button>
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

            <template #cell(col_3_minimum_access_level_for_push)="{ item }">
              <gl-form-select
                v-model="item.minimumAccessLevelForPush"
                class="gl-max-w-34"
                required
                :aria-label="$options.i18n.minimumAccessLevelForPush"
                :options="minimumAccessLevelOptions"
                :disabled="isProtectionRuleMinimumAccessLevelFormSelectDisabled(item)"
                @change="updatePackageProtectionRule(item)"
              />
            </template>

            <template #cell(col_4_actions)="{ item }">
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

          <div class="gl-display-flex gl-justify-content-center">
            <gl-keyset-pagination
              v-bind="packageProtectionRulesQueryPageInfo"
              class="gl-mb-3"
              @prev="onPrevPage"
              @next="onNextPage"
            />
          </div>
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
            <template #packageNamePattern>
              <strong>{{ protectionRuleMutationItem.col_1_package_name_pattern }}</strong>
            </template>
          </gl-sprintf>
        </p>
        <p>{{ $options.i18n.protectionRuleDeletionConfirmModal.descriptionConsequence }}</p>
      </gl-modal>
    </template>
  </settings-block>
</template>
