<script>
import {
  GlTable,
  GlButton,
  GlModal,
  GlTooltipDirective,
  GlLoadingIcon,
  GlSprintf,
} from '@gitlab/ui';
import { createAlert, VARIANT_INFO } from '~/alert';
import { __, s__ } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { duoContextExclusionHelpPath } from '../constants';
import ManageExclusionsDrawer from './manage_exclusions_drawer.vue';

export default {
  name: 'ExclusionSettings',
  components: {
    CrudComponent,
    GlTable,
    GlButton,
    GlModal,
    GlLoadingIcon,
    GlSprintf,
    ManageExclusionsDrawer,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    exclusionRules: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  i18n: {
    title: s__('DuoFeatures|GitLab Duo context exclusions'),
    description: s__(
      'DuoFeatures|Specify project files and directories that GitLab Duo will not access. Excluded content is never sent to AI models. %{linkStart}learn more%{linkEnd}.',
    ),
    manageExclusions: s__('DuoFeatures|Manage exclusions'),
    actionsLabel: __('Actions'),
    delete: __('Delete'),
    deleteRuleModalTitle: s__('DuoFeatures|Delete exclusion rule?'),
    deleteRuleModalText: s__('DuoFeatures|Do you want to delete this exclusion rule?'),
    ruleDeletedMessage: s__('DuoFeatures|The exclusion rule was deleted.'),
    deleteFailedMessage: s__('DuoFeatures|Failed to delete the exclusion rule. Try again.'),
    emptyStateMessage: s__(
      'DuoFeatures|No exclusion rules defined. Add a rule to exclude files from GitLab Duo context.',
    ),
  },
  data() {
    return {
      rules: [...this.exclusionRules],
      ruleToDelete: null,
      isDeleting: false,
      isManageDrawerOpen: false,
      duoContextExclusionHelpPath,
    };
  },
  computed: {
    fields() {
      return [
        {
          key: 'pattern',
          label: s__('DuoFeatures|Pattern'),
          tdClass: '!gl-align-middle',
        },
        {
          key: 'actions',
          label: this.$options.i18n.actionsLabel,
          thAlignRight: true,
          tdClass: 'gl-text-right !gl-align-middle',
        },
      ];
    },
    tableItems() {
      return this.rules.map((pattern, index) => ({
        id: index,
        pattern,
        isDeleting: false,
      }));
    },
    deleteProps() {
      return {
        text: this.$options.i18n.delete,
        attributes: { category: 'primary', variant: 'danger' },
      };
    },
    cancelProps() {
      return {
        text: __('Cancel'),
      };
    },
  },
  watch: {
    exclusionRules: {
      handler(newRules) {
        this.rules = [...newRules];
      },
      deep: true,
    },
  },
  methods: {
    openManageDrawer() {
      this.isManageDrawerOpen = true;
    },
    confirmDeleteRule(rule) {
      this.ruleToDelete = rule;
      this.$refs.deleteModal.show();
    },
    deleteRule() {
      if (!this.ruleToDelete) return;

      this.isDeleting = true;

      const index = this.ruleToDelete.id;
      this.rules.splice(index, 1);
      this.emitUpdate();

      createAlert({
        message: this.$options.i18n.ruleDeletedMessage,
        variant: VARIANT_INFO,
      });

      this.isDeleting = false;
      this.ruleToDelete = null;
    },
    emitUpdate() {
      this.$emit('update', this.rules);
    },
    closeManageDrawer() {
      this.isManageDrawerOpen = false;
    },
    saveExclusionRules(rules) {
      this.rules = [...rules];
      this.emitUpdate();
      this.closeManageDrawer();
    },
  },
};
</script>

<template>
  <div>
    <crud-component
      ref="crudComponent"
      :title="$options.i18n.title"
      :count="rules.length"
      icon="remove"
      data-testid="exclusion-settings-crud"
    >
      <template #description>
        <gl-sprintf :message="$options.i18n.description">
          <template #link="{ content }">
            <a :href="duoContextExclusionHelpPath" target="_blank" rel="noopener noreferrer">{{
              content
            }}</a>
          </template>
        </gl-sprintf>
      </template>
      <template #actions>
        <gl-button
          variant="default"
          data-testid="manage-exclusions-button"
          @click="openManageDrawer"
        >
          {{ $options.i18n.manageExclusions }}
        </gl-button>
      </template>
      <gl-table
        :empty-text="$options.i18n.emptyStateMessage"
        :fields="fields"
        :items="tableItems"
        stacked="md"
        show-empty
        class="b-table-fixed"
        data-testid="exclusion-rules-table"
      >
        <template #cell(pattern)="{ item }">
          <code class="gl-font-mono gl-rounded-sm gl-bg-gray-10 gl-px-2 gl-py-1">
            {{ item.pattern }}
          </code>
        </template>

        <template #cell(actions)="{ item }">
          <div class="table-action-buttons gl-flex gl-justify-end gl-gap-2">
            <gl-button
              v-gl-tooltip
              :disabled="isDeleting"
              category="tertiary"
              icon="remove"
              size="medium"
              :title="$options.i18n.delete"
              :aria-label="$options.i18n.delete"
              data-testid="delete-exclusion-rule"
              @click="confirmDeleteRule(item)"
            />
            <gl-loading-icon v-show="item.isDeleting" size="sm" :inline="true" />
          </div>
        </template>
      </gl-table>

      <gl-modal
        ref="deleteModal"
        modal-id="delete-exclusion-rule-modal"
        :title="$options.i18n.deleteRuleModalTitle"
        :action-primary="deleteProps"
        :action-cancel="cancelProps"
        data-testid="delete-exclusion-rule-modal"
        @primary="deleteRule"
      >
        <div class="well gl-mb-4">
          <code
            v-if="ruleToDelete"
            class="gl-font-mono gl-rounded-sm gl-bg-gray-10 gl-px-2 gl-py-1"
          >
            {{ ruleToDelete.pattern }}
          </code>
        </div>
        <p>
          <gl-sprintf :message="$options.i18n.deleteRuleModalText">
            <template #strong="{ content }">
              <strong>{{ content }}</strong>
            </template>
          </gl-sprintf>
        </p>
      </gl-modal>

      <manage-exclusions-drawer
        :open="isManageDrawerOpen"
        :exclusion-rules="rules"
        @save="saveExclusionRules"
        @close="closeManageDrawer"
      />
    </crud-component>
  </div>
</template>
