<script>
import { GlModal, GlCollapsibleListbox, GlFormGroup, GlSprintf, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import getProtectableBranches from '../graphql/queries/protectable_branches.query.graphql';

const wildcardsHelpDocLink = helpPagePath('user/project/repository/branches/protected', {
  anchor: 'protect-multiple-branches-with-wildcard-rules',
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
      return this.isWildcardAvailable ? [this.wildcardItem] : this.filteredOpenBranches;
    },
    filteredOpenBranches() {
      const openBranches = this.protectableBranches.map((item) => ({
        text: item,
        value: item,
      }));
      return openBranches.filter((item) => item.text.includes(this.searchQuery));
    },
    wildcardItem() {
      return { text: s__('BranchRules|Create wildcard'), value: this.searchQuery };
    },
    isWildcardAvailable() {
      return this.searchQuery.includes('*');
    },
    createRuleText() {
      return this.branchRuleName || s__('BranchRules|Select Branch or create wildcard');
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
        'BranchRules|%{linkStart}Wildcards%{linkEnd} such as *-stable or production/ are supported',
      );
    },
  },
  methods: {
    handleBranchRuleSearch(query) {
      this.searchQuery = query;
    },
    selectBranchRuleName(branchName) {
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
        <template v-if="isWildcardAvailable" #list-item="{ item }">
          {{ item.text }}
          <code>{{ searchQuery }}</code>
        </template>
      </gl-collapsible-listbox>
      <div data-testid="help-text" class="gl-mt-2 gl-text-subtle">
        <gl-sprintf :message="formDescriptionText">
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
