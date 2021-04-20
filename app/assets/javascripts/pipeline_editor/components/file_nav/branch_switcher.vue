<script>
import { GlDropdown, GlDropdownItem, GlDropdownSectionHeader, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DEFAULT_FAILURE } from '~/pipeline_editor/constants';
import getAvailableBranches from '~/pipeline_editor/graphql/queries/available_branches.graphql';
import getCurrentBranch from '~/pipeline_editor/graphql/queries/client/current_branch.graphql';

export default {
  i18n: {
    title: s__('Branches'),
    fetchError: s__('Unable to fetch branch list for this project.'),
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlIcon,
  },
  inject: ['projectFullPath'],
  apollo: {
    branches: {
      query: getAvailableBranches,
      variables() {
        return {
          projectFullPath: this.projectFullPath,
        };
      },
      update(data) {
        return data.project?.repository?.branches || [];
      },
      error() {
        this.$emit('showError', {
          type: DEFAULT_FAILURE,
          reasons: [this.$options.i18n.fetchError],
        });
      },
    },
    currentBranch: {
      query: getCurrentBranch,
    },
  },
  computed: {
    hasBranchList() {
      return this.branches?.length > 0;
    },
  },
};
</script>

<template>
  <gl-dropdown v-if="hasBranchList" class="gl-ml-2" :text="currentBranch" icon="branch">
    <gl-dropdown-section-header>
      {{ this.$options.i18n.title }}
    </gl-dropdown-section-header>
    <gl-dropdown-item
      v-for="branch in branches"
      :key="branch.name"
      :is-checked="currentBranch === branch.name"
      :is-check-item="true"
    >
      <gl-icon name="check" class="gl-visibility-hidden" />
      {{ branch.name }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
