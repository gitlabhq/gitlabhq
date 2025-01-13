<script>
import {
  GlAlert,
  GlBadge,
  GlButton,
  GlLoadingIcon,
  GlModal,
  GlModalDirective,
  GlSprintf,
  GlTable,
  GlTooltipDirective,
} from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import getContainerProtectionTagRulesQuery from '~/packages_and_registries/settings/project/graphql/queries/get_container_protection_tag_rules.query.graphql';
import deleteContainerProtectionTagRuleMutation from '~/packages_and_registries/settings/project/graphql/mutations/delete_container_protection_tag_rule.mutation.graphql';
import { __, s__ } from '~/locale';
import { MinimumAccessLevelOptions } from '~/packages_and_registries/settings/project/constants';

const MAX_LIMIT = 5;
const I18N_MINIMUM_ACCESS_LEVEL_TO_PUSH = s__('ContainerRegistry|Minimum access level to push');
const I18N_MINIMUM_ACCESS_LEVEL_TO_DELETE = s__('ContainerRegistry|Minimum access level to delete');

export default {
  components: {
    CrudComponent,
    GlAlert,
    GlBadge,
    GlButton,
    GlLoadingIcon,
    GlModal,
    GlSprintf,
    GlTable,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
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
      protectionRuleMutationInProgress: false,
      protectionRuleMutationItem: null,
      protectionRulesQueryPayload: { nodes: [], pageInfo: {} },
      protectionRulesQueryPaginationParams: { first: MAX_LIMIT },
    };
  },
  computed: {
    containsTableItems() {
      return this.protectionRulesQueryResult.length > 0;
    },
    isLoadingProtectionRules() {
      return this.$apollo.queries.protectionRulesQueryPayload.loading;
    },
    protectionRulesQueryResult() {
      return this.protectionRulesQueryPayload.nodes;
    },
    showTopLevelLoadingIcon() {
      return this.isLoadingProtectionRules && !this.containsTableItems;
    },
    showTableLoading() {
      return this.protectionRuleMutationInProgress || this.isLoadingProtectionRules;
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
    async deleteProtectionRule(protectionRule) {
      this.clearAlertMessage();

      this.protectionRuleMutationInProgress = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: deleteContainerProtectionTagRuleMutation,
          variables: { input: { id: protectionRule.id } },
        });
        const [errorMessage] = data?.deleteContainerProtectionTagRule?.errors ?? [];
        if (errorMessage) {
          this.alertErrorMessage = errorMessage;
          return;
        }
        this.refetchProtectionRules();
        this.$toast.show(s__('ContainerRegistry|Container protection rule deleted.'));
      } catch (error) {
        this.alertErrorMessage = error.message;
      } finally {
        this.resetProtectionRuleMutation();
      }
    },
    refetchProtectionRules() {
      this.$apollo.queries.protectionRulesQueryPayload.refetch();
    },
    resetProtectionRuleMutation() {
      this.protectionRuleMutationItem = null;
      this.protectionRuleMutationInProgress = false;
    },
    showProtectionRuleDeletionConfirmModal(protectionRule) {
      this.protectionRuleMutationItem = protectionRule;
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
    {
      key: 'rowActions',
      label: __('Actions'),
      thAlignRight: true,
      tdClass: '!gl-align-middle gl-text-right',
    },
  ],
  i18n: {
    deleteIconButton: __('Delete'),
    title: s__('ContainerRegistry|Protected container image tags'),
    protectionRuleDeletionConfirmModal: {
      title: s__('ContainerRegistry|Delete protection rule'),
      description: s__(
        'ContainerRegistry|Are you sure you want to delete the protected container tags rule %{tagNamePattern}?',
      ),
    },
  },
  MAX_LIMIT,
  modal: { id: 'delete-protection-tag-rule-confirmation-modal' },
  modalActionPrimary: {
    text: s__('ContainerRegistry|Delete rule'),
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
  <crud-component
    :title="$options.i18n.title"
    data-testid="project-container-protection-tag-rules-settings"
  >
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
            'ContainerRegistry|When a container image tag is protected, only certain user roles can create, update, and delete the protected tag, which helps to prevent unauthorized changes. You can add up to 5 protection rules per project.',
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

      <gl-loading-icon
        v-if="showTopLevelLoadingIcon"
        size="sm"
        class="gl-my-5"
        data-testid="loading-icon"
      />
      <gl-table
        v-else-if="containsTableItems"
        class="gl-border-t-1 gl-border-t-gray-100 gl-border-t-solid"
        :aria-label="$options.i18n.title"
        :busy="showTableLoading"
        :fields="$options.fields"
        :items="tableItems"
        stacked="md"
      >
        <template #table-busy>
          <gl-loading-icon size="sm" class="gl-my-5" data-testid="table-loading-icon" />
        </template>

        <template #cell(rowActions)="{ item }">
          <gl-button
            v-gl-tooltip
            v-gl-modal="$options.modal.id"
            category="tertiary"
            icon="remove"
            :title="$options.i18n.deleteIconButton"
            :aria-label="$options.i18n.deleteIconButton"
            @click="showProtectionRuleDeletionConfirmModal(item)"
          />
        </template>
      </gl-table>
      <p v-else data-testid="empty-text" class="gl-text-subtle">
        {{ s__('ContainerRegistry|No container image tags are protected.') }}
      </p>
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
          <gl-sprintf :message="$options.i18n.protectionRuleDeletionConfirmModal.description">
            <template #tagNamePattern>
              <strong>{{ protectionRuleMutationItem.tagNamePattern }}</strong>
            </template>
          </gl-sprintf>
        </p>
      </gl-modal>
    </template>
  </crud-component>
</template>
