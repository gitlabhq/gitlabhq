<script>
import {
  GlButton,
  GlCollapse,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlPopover,
  GlTooltipDirective,
  GlSprintf,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import WorkItemDrawer from '~/work_items/components/work_item_drawer.vue';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import mergeRequestRelatedWorkItemsQuery from '~/sidebar/queries/merge_request_related_work_items.query.graphql';
import { DETAIL_VIEW_QUERY_PARAM_NAME, VIEW_CONTEXT } from '~/work_items/constants';
import { getParameterByName, removeParams, updateHistory } from '~/lib/utils/url_utility';
import { MR_WORK_ITEM_RELATIONSHIP_TYPES } from '~/sidebar/constants';

export default {
  name: 'MRRelatedWorkItems',
  components: {
    GlButton,
    GlCollapse,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlPopover,
    GlSprintf,
    WorkItemDrawer,
  },
  viewContext: VIEW_CONTEXT.drawerMergeRequest,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['fullPath', 'id'],
  data() {
    return {
      activeItem: null,
      isCollapsed: true,
      params: null,
      allItems: [],
    };
  },
  apollo: {
    allItems: {
      query: mergeRequestRelatedWorkItemsQuery,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_MERGE_REQUEST, this.id),
        };
      },
      update(data) {
        return data?.mergeRequest?.linkedWorkItems || [];
      },
      result() {
        this.checkDrawerParams();
      },
      error() {
        createAlert({
          message: __('Something went wrong while fetching related work items.'),
        });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.allItems.loading;
    },
    closingWorkItems() {
      return this.allItems
        .filter((i) => i.linkType === MR_WORK_ITEM_RELATIONSHIP_TYPES.closing)
        .map((i) => i.workItem);
    },
    mentionedWorkItems() {
      return this.allItems
        .filter((i) => i.linkType === MR_WORK_ITEM_RELATIONSHIP_TYPES.mentioned)
        .map((i) => i.workItem);
    },
    showCollapsedState() {
      return this.allItems.length > 2;
    },
    collapsedSummary() {
      const parts = [];
      if (this.closingWorkItems.length > 0) {
        parts.push(`${__('Closing')} ${this.closingWorkItems.length}`);
      }
      if (this.mentionedWorkItems.length > 0) {
        parts.push(`${__('Mentioned')} ${this.mentionedWorkItems.length}`);
      }
      return parts.join(', ');
    },
  },
  watch: {
    params(newParams) {
      const item = this.allItems.find(
        (i) => getIdFromGraphQLId(i.workItem.id) === newParams.id,
      )?.workItem;
      if (item) {
        this.activeItem = item;
      } else {
        updateHistory({
          url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME]),
        });
      }
    },
  },
  created() {
    window.addEventListener('popstate', this.checkDrawerParams);
  },
  beforeDestroy() {
    window.removeEventListener('popstate', this.checkDrawerParams);
  },
  methods: {
    openDrawer(event, item) {
      if (event.metaKey || event.ctrlKey) {
        return;
      }
      event.preventDefault();
      this.activeItem = item;
    },
    checkDrawerParams() {
      const queryParam = getParameterByName(DETAIL_VIEW_QUERY_PARAM_NAME);

      if (!queryParam) {
        this.activeItem = null;
        return;
      }

      this.parseDrawerParams(queryParam);
    },
    parseDrawerParams(queryParam) {
      try {
        this.params = JSON.parse(atob(queryParam));
      } catch {
        updateHistory({
          url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME]),
        });
      }
    },
  },
};
</script>

<template>
  <div class="gl-leading-20 gl-text-default">
    <div class="gl-flex gl-items-center gl-font-bold gl-leading-24 gl-text-default">
      <span data-testid="title" class="hide-collapsed">{{ __('Work Items') }}</span>
      <gl-loading-icon v-if="isLoading" size="sm" inline class="hide-collapsed gl-ml-2" />
      <gl-button
        v-if="showCollapsedState"
        v-show="!isCollapsed"
        v-gl-tooltip
        :title="__('Collapse work items')"
        category="tertiary"
        icon="chevron-down"
        size="small"
        class="-gl-mr-2 gl-ml-auto !gl-p-0"
        @click="isCollapsed = true"
      />
      <gl-icon
        v-if="!isLoading && allItems.length === 0"
        id="related-work-items-info"
        name="information-o"
        class="gl-ml-auto gl-cursor-pointer gl-text-subtle"
      />
    </div>
    <template v-if="!isLoading && allItems.length > 0">
      <div v-if="showCollapsedState" v-show="isCollapsed" class="hide-collapsed gl-mt-2">
        <gl-link class="gl-text-sm !gl-text-link" @click="isCollapsed = false">
          {{ collapsedSummary }}
        </gl-link>
      </div>
      <gl-collapse :visible="!showCollapsedState || !isCollapsed" class="hide-collapsed">
        <div v-if="closingWorkItems.length > 0" class="gl-mt-2">
          <span class="gl-text-sm gl-font-bold gl-text-subtle">{{ __('Closing') }}</span>
          <ul class="gl-m-0 gl-list-none gl-p-0">
            <li v-for="item in closingWorkItems" :key="item.id" class="gl-mt-1">
              <gl-link
                :href="item.webPath"
                class="has-popover gl-block gl-truncate"
                data-reference-type="work_item"
                data-placement="top"
                :data-iid="item.iid"
                :data-project-path="item.namespace.fullPath"
                @click="openDrawer($event, item)"
              >
                {{ item.title }}
              </gl-link>
            </li>
          </ul>
        </div>
        <div v-if="mentionedWorkItems.length > 0" class="gl-mt-3">
          <span class="gl-text-sm gl-font-bold gl-text-subtle">{{ __('Mentioned') }}</span>
          <ul class="gl-m-0 gl-list-none gl-p-0">
            <li v-for="item in mentionedWorkItems" :key="item.id" class="gl-mt-1">
              <gl-link
                :href="item.webPath"
                class="has-popover gl-block gl-truncate"
                data-reference-type="work_item"
                data-placement="top"
                :data-iid="item.iid"
                :data-project-path="item.namespace.fullPath"
                @click="openDrawer($event, item)"
              >
                {{ item.title }}
              </gl-link>
            </li>
          </ul>
        </div>
      </gl-collapse>
    </template>
    <template v-else-if="!isLoading">
      <span class="hide-collapsed gl-text-subtle">{{ __('None') }}</span>
      <gl-popover target="related-work-items-info" placement="top">
        <template #title>{{ __('Work item links') }}</template>
        <gl-sprintf
          :message="
            __(
              'To link work items, you can add %{linkStart}closing patterns%{linkEnd} to the description.',
            )
          "
        >
          <template #link="{ content }">
            <gl-link
              href="https://docs.gitlab.com/user/project/issues/managing_issues/#closing-issues-automatically"
              target="_blank"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </gl-popover>
    </template>
    <work-item-drawer
      :active-item="activeItem"
      :view-context="$options.viewContext"
      :open="activeItem !== null"
      issuable-type="Issue"
      @close="activeItem = null"
    />
  </div>
</template>
