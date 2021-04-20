<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownText,
  GlSearchBoxByType,
  GlDropdownDivider,
  GlLoadingIcon,
} from '@gitlab/ui';
import { mapGetters, mapActions } from 'vuex';
import BoardEditableItem from '~/boards/components/sidebar/board_editable_item.vue';
import createFlash from '~/flash';
import { __, s__ } from '~/locale';
import projectMilestones from '../../graphql/project_milestones.query.graphql';

export default {
  components: {
    BoardEditableItem,
    GlDropdown,
    GlLoadingIcon,
    GlDropdownItem,
    GlDropdownText,
    GlSearchBoxByType,
    GlDropdownDivider,
  },
  data() {
    return {
      milestones: [],
      searchTitle: '',
      loading: false,
      edit: false,
    };
  },
  apollo: {
    milestones: {
      query: projectMilestones,
      debounce: 250,
      skip() {
        return !this.edit;
      },
      variables() {
        return {
          fullPath: this.projectPath,
          searchTitle: this.searchTitle,
          state: 'active',
          includeAncestors: true,
        };
      },
      update(data) {
        const edges = data?.project?.milestones?.edges ?? [];
        return edges.map((item) => item.node);
      },
      error() {
        createFlash({ message: this.$options.i18n.fetchMilestonesError });
      },
    },
  },
  computed: {
    ...mapGetters(['activeBoardItem']),
    hasMilestone() {
      return this.activeBoardItem.milestone !== null;
    },
    groupFullPath() {
      const { referencePath = '' } = this.activeBoardItem;
      return referencePath.slice(0, referencePath.indexOf('/'));
    },
    projectPath() {
      const { referencePath = '' } = this.activeBoardItem;
      return referencePath.slice(0, referencePath.indexOf('#'));
    },
    dropdownText() {
      return this.activeBoardItem.milestone?.title ?? this.$options.i18n.noMilestone;
    },
  },
  methods: {
    ...mapActions(['setActiveIssueMilestone']),
    handleOpen() {
      this.edit = true;
      this.$refs.dropdown.show();
    },
    handleClose() {
      this.edit = false;
      this.$refs.sidebarItem.collapse();
    },
    async setMilestone(milestoneId) {
      this.loading = true;
      this.searchTitle = '';
      this.handleClose();

      try {
        const input = { milestoneId, projectPath: this.projectPath };
        await this.setActiveIssueMilestone(input);
      } catch (e) {
        createFlash({ message: this.$options.i18n.updateMilestoneError });
      } finally {
        this.loading = false;
      }
    },
  },
  i18n: {
    milestone: __('Milestone'),
    noMilestone: __('No milestone'),
    assignMilestone: __('Assign milestone'),
    noMilestonesFound: s__('Milestones|No milestones found'),
    fetchMilestonesError: __('There was a problem fetching milestones.'),
    updateMilestoneError: __('An error occurred while updating the milestone.'),
  },
};
</script>

<template>
  <board-editable-item
    ref="sidebarItem"
    :title="$options.i18n.milestone"
    :loading="loading"
    data-testid="sidebar-milestones"
    @open="handleOpen"
    @close="handleClose"
  >
    <template v-if="hasMilestone" #collapsed>
      <strong class="gl-text-gray-900">{{ activeBoardItem.milestone.title }}</strong>
    </template>
    <gl-dropdown
      ref="dropdown"
      :text="dropdownText"
      :header-text="$options.i18n.assignMilestone"
      block
      @hide="handleClose"
    >
      <gl-search-box-by-type ref="search" v-model.trim="searchTitle" class="gl-m-3" />
      <gl-dropdown-item
        data-testid="no-milestone-item"
        :is-check-item="true"
        :is-checked="!activeBoardItem.milestone"
        @click="setMilestone(null)"
      >
        {{ $options.i18n.noMilestone }}
      </gl-dropdown-item>
      <gl-dropdown-divider />
      <gl-loading-icon v-if="$apollo.loading" class="gl-py-4" />
      <template v-else-if="milestones.length > 0">
        <gl-dropdown-item
          v-for="milestone in milestones"
          :key="milestone.id"
          :is-check-item="true"
          :is-checked="activeBoardItem.milestone && milestone.id === activeBoardItem.milestone.id"
          data-testid="milestone-item"
          @click="setMilestone(milestone.id)"
        >
          {{ milestone.title }}
        </gl-dropdown-item>
      </template>
      <gl-dropdown-text v-else data-testid="no-milestones-found">
        {{ $options.i18n.noMilestonesFound }}
      </gl-dropdown-text>
    </gl-dropdown>
  </board-editable-item>
</template>
