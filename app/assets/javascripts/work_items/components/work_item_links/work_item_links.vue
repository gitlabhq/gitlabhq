<script>
import { GlButton, GlBadge, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_WORK_ITEM } from '~/graphql_shared/constants';
import {
  STATE_OPEN,
  WIDGET_ICONS,
  WORK_ITEM_STATUS_TEXT,
  WIDGET_TYPE_HIERARCHY,
} from '../../constants';
import getWorkItemLinksQuery from '../../graphql/work_item_links.query.graphql';
import WorkItemLinksForm from './work_item_links_form.vue';
import WorkItemLinksMenu from './work_item_links_menu.vue';

export default {
  components: {
    GlButton,
    GlBadge,
    GlIcon,
    GlLoadingIcon,
    WorkItemLinksForm,
    WorkItemLinksMenu,
  },
  props: {
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
    issuableId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  apollo: {
    children: {
      query: getWorkItemLinksQuery,
      variables() {
        return {
          id: this.issuableGid,
        };
      },
      update(data) {
        return (
          data.workItem.widgets.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY)?.children
            .nodes ?? []
        );
      },
      skip() {
        return !this.issuableId;
      },
    },
  },
  data() {
    return {
      isShownAddForm: false,
      isOpen: true,
      children: [],
    };
  },
  computed: {
    // Only used for children for now but should be extended later to support parents and siblings
    isChildrenEmpty() {
      return this.children?.length === 0;
    },
    toggleIcon() {
      return this.isOpen ? 'chevron-lg-up' : 'chevron-lg-down';
    },
    toggleLabel() {
      return this.isOpen
        ? s__('WorkItem|Collapse child items')
        : s__('WorkItem|Expand child items');
    },
    issuableGid() {
      return this.issuableId ? convertToGraphQLId(TYPE_WORK_ITEM, this.issuableId) : null;
    },
    isLoading() {
      return this.$apollo.queries.children.loading;
    },
    childrenIds() {
      return this.children.map((c) => c.id);
    },
  },
  methods: {
    badgeVariant(state) {
      return state === STATE_OPEN ? 'success' : 'info';
    },
    toggle() {
      this.isOpen = !this.isOpen;
    },
    toggleAddForm() {
      this.isShownAddForm = !this.isShownAddForm;
    },
    addChild(child) {
      this.children = [child, ...this.children];
    },
  },
  i18n: {
    title: s__('WorkItem|Child items'),
    emptyStateMessage: s__(
      'WorkItem|No child items are currently assigned. Use child items to prioritize tasks that your team should complete in order to accomplish your goals!',
    ),
    addChildButtonLabel: s__('WorkItem|Add a task'),
  },
  WIDGET_TYPE_TASK_ICON: WIDGET_ICONS.TASK,
  WORK_ITEM_STATUS_TEXT,
};
</script>

<template>
  <div class="gl-rounded-base gl-border-1 gl-border-solid gl-border-gray-100 gl-bg-gray-10">
    <div
      class="gl-p-4 gl-display-flex gl-justify-content-space-between"
      :class="{ 'gl-border-b-1 gl-border-b-solid gl-border-b-gray-100': isOpen }"
    >
      <h5 class="gl-m-0 gl-line-height-32 gl-flex-grow-1">{{ $options.i18n.title }}</h5>
      <gl-button
        v-if="!isShownAddForm"
        category="secondary"
        data-testid="toggle-add-form"
        @click="toggleAddForm"
      >
        {{ $options.i18n.addChildButtonLabel }}
      </gl-button>
      <div class="gl-border-l-1 gl-border-l-solid gl-border-l-gray-50 gl-pl-4 gl-ml-3">
        <gl-button
          category="tertiary"
          :icon="toggleIcon"
          :aria-label="toggleLabel"
          data-testid="toggle-links"
          @click="toggle"
        />
      </div>
    </div>
    <div
      v-if="isOpen"
      class="gl-bg-gray-10 gl-p-4 gl-rounded-bottom-left-base gl-rounded-bottom-right-base"
      data-testid="links-body"
    >
      <gl-loading-icon v-if="isLoading" color="dark" class="gl-my-3" />

      <template v-else>
        <div v-if="isChildrenEmpty && !isShownAddForm" data-testid="links-empty">
          <p class="gl-my-3">
            {{ $options.i18n.emptyStateMessage }}
          </p>
        </div>
        <work-item-links-form
          v-if="isShownAddForm"
          data-testid="add-links-form"
          :issuable-gid="issuableGid"
          :children-ids="childrenIds"
          @cancel="toggleAddForm"
          @addWorkItemChild="addChild"
        />
        <div
          v-for="child in children"
          :key="child.id"
          class="gl-relative gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row gl-overflow-break-word gl-min-w-0 gl-bg-white gl-mb-3 gl-py-3 gl-px-4 gl-border gl-border-gray-100 gl-rounded-base gl-line-height-32"
          data-testid="links-child"
        >
          <div>
            <gl-icon :name="$options.WIDGET_TYPE_TASK_ICON" class="gl-mr-3 gl-text-gray-700" />
            <span class="gl-word-break-all">{{ child.title }}</span>
          </div>
          <div
            class="gl-ml-0 gl-sm-ml-auto! gl-mt-3 gl-sm-mt-0 gl-display-inline-flex gl-align-items-center"
          >
            <gl-badge :variant="badgeVariant(child.state)">
              <span class="gl-sm-display-block">{{
                $options.WORK_ITEM_STATUS_TEXT[child.state]
              }}</span>
            </gl-badge>
            <work-item-links-menu :work-item-id="child.id" :parent-work-item-id="issuableGid" />
          </div>
        </div>
      </template>
    </div>
  </div>
</template>
