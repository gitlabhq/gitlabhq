<script>
import { GlButton, GlSearchBoxByClick, GlTabs, GlTab } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import { s__ } from '~/locale';
import ImportProjectsTable from './import_projects_table.vue';
import GithubOrganizationsBox from './github_organizations_box.vue';

export default {
  components: {
    ImportProjectsTable,
    GithubOrganizationsBox,
    GlButton,
    GlSearchBoxByClick,
    GlTab,
    GlTabs,
  },
  inheritAttrs: false,
  data() {
    return {
      selectedRelationTypeTabIdx: 0,
    };
  },
  computed: {
    ...mapState({
      selectedOrganization: (state) => state.filter.organization_login ?? '',
      nameFilter: (state) => state.filter.filter ?? '',
    }),
    ...mapGetters(['isImportingAnyRepo', 'hasImportableRepos']),
    isNameFilterDisabled() {
      return (
        this.$options.relationTypes[this.selectedRelationTypeTabIdx].showOrganizationFilter &&
        !this.selectedOrganization
      );
    },
  },
  watch: {
    selectedRelationTypeTabIdx: {
      immediate: true,
      handler(newIdx) {
        const { backendFilter } = this.$options.relationTypes[newIdx];
        this.setFilter({ ...backendFilter, organization_login: '', filter: '' });
      },
    },
  },
  methods: {
    ...mapActions(['setFilter']),
    selectOrganization(org) {
      this.selectedOrganization = org;
      this.setFilter();
    },
  },

  relationTypes: [
    { title: s__('ImportProjects|Owned'), backendFilter: { relation_type: 'owned' } },
    { title: s__('ImportProjects|Collaborated'), backendFilter: { relation_type: 'collaborated' } },
    {
      title: s__('ImportProjects|Organization'),
      backendFilter: { relation_type: 'organization' },
      showOrganizationFilter: true,
    },
  ],
};
</script>
<template>
  <import-projects-table v-bind="$attrs">
    <template #filter="{ importAllButtonText, showImportAllModal }">
      <gl-tabs v-model="selectedRelationTypeTabIdx" content-class="!gl-py-0 gl-mb-3">
        <gl-tab v-for="tab in $options.relationTypes" :key="tab.title" :title="tab.title">
          <div
            class="gl-flex gl-flex-wrap gl-justify-between gl-gap-3 gl-border-0 gl-border-b-1 gl-border-solid gl-border-b-default gl-bg-subtle gl-p-5"
          >
            <form class="gl-mr-3 gl-flex gl-grow" novalidate @submit.prevent>
              <github-organizations-box
                v-if="tab.showOrganizationFilter"
                class="gl-mr-3"
                :value="selectedOrganization"
                @input="setFilter({ organization_login: $event })"
              />
              <gl-search-box-by-click
                name="filter"
                :disabled="isNameFilterDisabled"
                :value="nameFilter"
                :placeholder="__('Filter by name')"
                autofocus
                @submit="setFilter({ filter: $event })"
                @clear="setFilter({ filter: '' })"
              />
            </form>
            <gl-button
              variant="confirm"
              :loading="isImportingAnyRepo"
              :disabled="!hasImportableRepos"
              type="button"
              @click="showImportAllModal"
            >
              {{ importAllButtonText }}
            </gl-button>
          </div>
        </gl-tab>
      </gl-tabs>
    </template>
  </import-projects-table>
</template>
