<script>
import { GlBreadcrumb } from '@gitlab/ui';
import { STATUS_OPEN } from '~/issues/constants';
import { s__, __ } from '~/locale';
import { DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';
import { urlSortParams } from '~/work_items/list/constants';
import { planningViewAllItemsFilters } from '~/work_items/pages/planning_view_state';

import { ROUTES, WORK_ITEM_TYPE_NAME_TICKET } from '../constants';

export default {
  components: {
    GlBreadcrumb,
  },
  inject: {
    workItemType: {
      default: null,
    },
  },
  props: {
    staticBreadcrumbs: {
      type: Array,
      required: true,
    },
  },
  computed: {
    isServiceDeskList() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_TICKET;
    },
    listName() {
      if (this.isServiceDeskList) {
        return __('Service Desk');
      }

      return s__('WorkItem|Work items');
    },
    breadcrumbType() {
      if (this.isServiceDeskList) {
        return 'service_desk';
      }

      return 'work_items';
    },
    crumbs() {
      const session = planningViewAllItemsFilters.value;
      const indexQuery = session
        ? {
            sort: urlSortParams[session.sortKey],
            state: STATUS_OPEN,
            first_page_size: DEFAULT_PAGE_SIZE,
          }
        : undefined;

      const indexCrumb = {
        text: this.listName,
        to: {
          name: ROUTES.index,
          query: indexQuery,
          params: { type: this.breadcrumbType },
        },
      };

      const crumbs = [...this.staticBreadcrumbs, indexCrumb];

      if (this.$route.name === ROUTES.new) {
        crumbs.push({
          text: s__('WorkItem|New'),
          to: { name: ROUTES.new, params: { type: this.breadcrumbType } },
        });
      }

      if (this.$route.name === ROUTES.workItem) {
        crumbs.push({
          text: `#${this.$route.params.iid}`,
          to: {
            name: ROUTES.workItem,
            params: {
              type: this.$route.params.type,
              iid: this.$route.params.iid,
            },
          },
        });
      }

      return crumbs;
    },
  },
};
</script>

<template>
  <gl-breadcrumb :key="crumbs.length" :items="crumbs" :auto-resize="true" />
</template>
