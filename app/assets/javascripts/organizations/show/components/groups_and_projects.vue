<script>
import { GlCollapsibleListbox, GlLink } from '@gitlab/ui';
import { isEqual } from 'lodash';
import { s__, __ } from '~/locale';
import GroupsView from '../../shared/components/groups_view.vue';
import ProjectsView from '../../shared/components/projects_view.vue';
import { onPageChange } from '../../shared/utils';
import { QUERY_PARAM_END_CURSOR, QUERY_PARAM_START_CURSOR } from '../../shared/constants';
import { RESOURCE_TYPE_GROUPS, RESOURCE_TYPE_PROJECTS } from '../../constants';
import { FILTER_FREQUENTLY_VISITED, GROUPS_AND_PROJECTS_PER_PAGE } from '../constants';
import { buildDisplayListboxItem } from '../utils';

export default {
  name: 'OrganizationFrontPageGroupsAndProjects',
  i18n: {
    displayListboxLabel: __('Display'),
    viewAll: s__('Organization|View all'),
  },
  displayListboxLabelId: 'display-listbox-label',
  components: { GlCollapsibleListbox, GlLink },
  displayListboxItems: [
    buildDisplayListboxItem({
      filter: FILTER_FREQUENTLY_VISITED,
      resourceType: RESOURCE_TYPE_PROJECTS,
      text: s__('Organization|Frequently visited projects'),
    }),
    buildDisplayListboxItem({
      filter: FILTER_FREQUENTLY_VISITED,
      resourceType: RESOURCE_TYPE_GROUPS,
      text: s__('Organization|Frequently visited groups'),
    }),
  ],
  PER_PAGE: GROUPS_AND_PROJECTS_PER_PAGE,
  props: {
    groupsAndProjectsOrganizationPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    displayListboxSelected() {
      const { display } = this.$route.query;
      const [{ value: fallbackSelected }] = this.$options.displayListboxItems;

      return (
        this.$options.displayListboxItems.find(({ value }) => value === display)?.value ||
        fallbackSelected
      );
    },
    startCursor() {
      return this.$route.query[QUERY_PARAM_START_CURSOR] || null;
    },
    endCursor() {
      return this.$route.query[QUERY_PARAM_END_CURSOR] || null;
    },
    resourceTypeSelected() {
      return [RESOURCE_TYPE_PROJECTS, RESOURCE_TYPE_GROUPS].find((resourceType) =>
        this.displayListboxSelected.endsWith(resourceType),
      );
    },
    routerView() {
      switch (this.resourceTypeSelected) {
        case RESOURCE_TYPE_GROUPS:
          return GroupsView;

        case RESOURCE_TYPE_PROJECTS:
          return ProjectsView;

        default:
          return ProjectsView;
      }
    },
    groupsAndProjectsOrganizationPathWithQueryParam() {
      return `${this.groupsAndProjectsOrganizationPath}?display=${this.resourceTypeSelected}`;
    },
  },
  methods: {
    pushQuery(query) {
      const currentQuery = this.$route.query;

      if (isEqual(currentQuery, query)) {
        return;
      }

      this.$router.push({ query });
    },
    onDisplayListboxSelect(display) {
      this.pushQuery({ display });
    },
    onPageChange(pagination) {
      this.pushQuery(onPageChange({ ...pagination, routeQuery: this.$route.query }));
    },
  },
};
</script>

<template>
  <div class="gl-mt-7">
    <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
      <div>
        <label
          :id="$options.displayListboxLabelId"
          class="gl-display-block gl-mb-2"
          data-testid="label"
          >{{ $options.i18n.displayListboxLabel }}</label
        >
        <gl-collapsible-listbox
          block
          toggle-class="gl-w-30"
          :selected="displayListboxSelected"
          :items="$options.displayListboxItems"
          :toggle-aria-labelled-by="$options.displayListboxLabelId"
          @select="onDisplayListboxSelect"
        />
      </div>
      <gl-link class="gl-mt-5" :href="groupsAndProjectsOrganizationPathWithQueryParam">{{
        $options.i18n.viewAll
      }}</gl-link>
    </div>
    <component
      :is="routerView"
      should-show-empty-state-buttons
      class="gl-mt-5"
      :start-cursor="startCursor"
      :end-cursor="endCursor"
      :per-page="$options.PER_PAGE"
      @page-change="onPageChange"
    />
  </div>
</template>
