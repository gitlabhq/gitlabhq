<script>
import { GlModal, GlCollapsibleListbox, GlFormGroup, GlSprintf, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import getProtectableBranches from '../graphql/queries/protectable_branches.query.graphql';

const wildcardsHelpDocLink = helpPagePath('user/project/repository/branches/protected', {
  anchor: 'use-wildcard-rules',
});
export default {
  name: 'BranchRuleModal',
  wildcardsHelpDocLink,
  components: {
    GlModal,
    GlCollapsibleListbox,
    GlFormGroup,
    GlSprintf,
    GlLink,
  },
  inject: {
    projectPath: {
      default: '',
    },
  },
  props: {
    id: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    actionPrimaryText: {
      type: String,
      required: true,
    },
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    project: {
      query: getProtectableBranches,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update({ project: { protectableBranches } }) {
        this.protectableBranches = protectableBranches;
      },
    },
  },
  data() {
    return {
      protectableBranches: [],
      branchRuleName: '',
      searchQuery: '',
    };
  },
  computed: {
    createRuleItems() {
      const items = [...this.filteredOpenBranches];

      if (this.filteredOpenBranches.length === 0 && this.searchQuery.trim()) {
        items.push(this.noResultsItem);
      }

      if (this.isWildcardAvailable) {
        items.push(this.wildcardItem);
      }

      if (this.isBranchNameAvailable) {
        items.push(this.branchNameItem);
      }

      return items;
    },
    filteredOpenBranches() {
      const openBranches = this.protectableBranches.map((item) => ({
        text: item,
        value: item,
      }));
      return openBranches.filter((item) => item.text.includes(this.searchQuery));
    },
    wildcardItem() {
      return {
        text: s__('BranchRules|Create wildcard'),
        value: this.searchQuery,
        isWildcard: true,
      };
    },
    branchNameItem() {
      return {
        text: s__('BranchRules|Create branch rule'),
        value: this.searchQuery,
        isBranchName: true,
      };
    },
    noResultsItem() {
      return {
        text: s__('BranchRules|No branch rules found'),
        value: '',
        isNoResults: true,
        disabled: true,
      };
    },
    hasMatchingBranch() {
      return this.filteredOpenBranches.some((branch) => branch.text === this.searchQuery);
    },
    isBranchAvailable() {
      return this.searchQuery.trim() && !this.hasMatchingBranch;
    },
    isWildcardAvailable() {
      return this.isBranchAvailable && this.searchQuery.includes('*');
    },
    isBranchNameAvailable() {
      return this.isBranchAvailable && !this.searchQuery.includes('*');
    },
    createRuleText() {
      return this.branchRuleName || s__('BranchRules|Select branch or create rule');
    },
    primaryProps() {
      return {
        text: this.actionPrimaryText,
        attributes: {
          variant: 'confirm',
          disabled: !this.branchRuleName,
        },
      };
    },
    cancelProps() {
      return {
        text: s__('BranchRules|Cancel'),
      };
    },
    formDescriptionText() {
      return s__(
        'BranchRules|Select an existing branch, create a branch rule, or use wildcards such as %{stable} or %{production}. Branch names are case-sensitive. %{linkStart}Learn more.%{linkEnd}',
      );
    },
  },
  expose: ['show'],
  methods: {
    handleBranchRuleSearch(query) {
      this.searchQuery = query;
    },
    selectBranchRuleName(branchName) {
      if (branchName === this.noResultsItem.value) {
        return;
      }
      this.branchRuleName = branchName;
    },
    show() {
      this.$refs[this.id].show();
    },
  },
};
</script>

<template>
  <gl-modal
    :ref="id"
    :modal-id="id"
    :title="title"
    :action-primary="primaryProps"
    :action-cancel="cancelProps"
    @primary="$emit('primary', branchRuleName)"
    @cancel="$emit('cancel')"
    @change="searchQuery = ''"
  >
    <gl-form-group :label="s__('BranchRules|Branch name or pattern')">
      <gl-collapsible-listbox
        v-model="branchRuleName"
        searchable
        :items="createRuleItems"
        :toggle-text="createRuleText"
        block
        @search="handleBranchRuleSearch"
        @select="selectBranchRuleName"
      >
        <template #list-item="{ item }">
          <div>
            <div>
              <div :class="{ 'gl-text-subtle gl-opacity-6': item.isNoResults }">
                {{ item.text }}
              </div>
              <div v-if="item.isWildcard || item.isBranchName" class="gl-mt-2">
                <code class="gl-display-block gl-text-subtle">
                  {{ searchQuery }}
                </code>
              </div>
            </div>
          </div></template
        >
      </gl-collapsible-listbox>
      <div data-testid="help-text" class="gl-mt-2 gl-text-subtle">
        <gl-sprintf :message="formDescriptionText">
          <template #stable>
            <code>{{ __('*-stable') }}</code>
          </template>
          <template #production>
            <code>{{ __('production/*') }}</code>
          </template>
          <template #link="{ content }">
            <gl-link :href="$options.wildcardsHelpDocLink">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </div>
    </gl-form-group>
  </gl-modal>
</template>
