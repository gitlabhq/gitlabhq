<script>
import { GlCollapsibleListbox, GlLink } from '@gitlab/ui';
import { isEqual } from 'lodash';
import { s__, __ } from '~/locale';
import GroupsView from '~/organizations/shared/components/groups_view.vue';
import ProjectsView from '~/organizations/shared/components/projects_view.vue';
import { calculateGraphQLPaginationQueryParams } from '~/graphql_shared/utils';
import {
  RESOURCE_TYPE_GROUPS,
  RESOURCE_TYPE_PROJECTS,
  SORT_CREATED_AT,
  SORT_UPDATED_AT,
  SORT_DIRECTION_DESC,
} from '~/organizations/shared/constants';
import { QUERY_PARAM_END_CURSOR, QUERY_PARAM_START_CURSOR } from '~/graphql_shared/constants';
import { GROUPS_AND_PROJECTS_PER_PAGE } from '../constants';
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
      sortName: SORT_UPDATED_AT,
      resourceType: RESOURCE_TYPE_GROUPS,
      text: s__('Organization|Recently updated groups'),
    }),
    buildDisplayListboxItem({
      sortName: SORT_CREATED_AT,
      resourceType: RESOURCE_TYPE_GROUPS,
      text: s__('Organization|Recently created groups'),
    }),
    buildDisplayListboxItem({
      sortName: SORT_UPDATED_AT,
      resourceType: RESOURCE_TYPE_PROJECTS,
      text: s__('Organization|Recently updated projects'),
    }),
    buildDisplayListboxItem({
      sortName: SORT_CREATED_AT,
      resourceType: RESOURCE_TYPE_PROJECTS,
      text: s__('Organization|Recently created projects'),
    }),
  ],
  PER_PAGE: GROUPS_AND_PROJECTS_PER_PAGE,
  SORT_DIRECTION_DESC,
  props: {
    groupsAndProjectsOrganizationPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    displayListboxSelected() {
      const { display } = this.$route.query;
      const [fallbackSelected] = this.$options.displayListboxItems;

      return (
        this.$options.displayListboxItems.find(({ value }) => value === display) || fallbackSelected
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
        this.displayListboxSelected.value.endsWith(resourceType),
      );
    },
    sortName() {
      return this.displayListboxSelected.sortName;
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
      this.pushQuery(
        calculateGraphQLPaginationQueryParams({ ...pagination, routeQuery: this.$route.query }),
      );
    },
  },
};
</script>

<template>
  <div class="gl-mt-7">
    <div class="gl-flex gl-items-center gl-justify-between">
      <div>
        <label :id="$options.displayListboxLabelId" class="gl-mb-2 gl-block" data-testid="label">{{
          $options.i18n.displayListboxLabel
        }}</label>
        <gl-collapsible-listbox
          block
          toggle-class="gl-w-30"
          :selected="displayListboxSelected.value"
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
      :sort-name="sortName"
      :sort-direction="$options.SORT_DIRECTION_DESC"
      @page-change="onPageChange"
    />
  </div>
</template>
