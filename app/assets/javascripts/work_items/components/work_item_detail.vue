<script>
import { GlAlert, GlSkeletonLoader, GlIcon, GlButton } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  i18n,
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_LABELS,
  WIDGET_TYPE_DESCRIPTION,
  WIDGET_TYPE_WEIGHT,
  WIDGET_TYPE_HIERARCHY,
} from '../constants';
import workItemQuery from '../graphql/work_item.query.graphql';
import workItemTitleSubscription from '../graphql/work_item_title.subscription.graphql';
import WorkItemActions from './work_item_actions.vue';
import WorkItemState from './work_item_state.vue';
import WorkItemTitle from './work_item_title.vue';
import WorkItemDescription from './work_item_description.vue';
import WorkItemAssignees from './work_item_assignees.vue';
import WorkItemLabels from './work_item_labels.vue';
import WorkItemWeight from './work_item_weight.vue';

export default {
  i18n,
  components: {
    GlAlert,
    GlButton,
    GlSkeletonLoader,
    GlIcon,
    WorkItemAssignees,
    WorkItemActions,
    WorkItemDescription,
    WorkItemLabels,
    WorkItemTitle,
    WorkItemState,
    WorkItemWeight,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    isModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
    workItemParentId: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      error: undefined,
      workItem: {},
    };
  },
  apollo: {
    workItem: {
      query: workItemQuery,
      variables() {
        return {
          id: this.workItemId,
        };
      },
      skip() {
        return !this.workItemId;
      },
      error() {
        this.error = this.$options.i18n.fetchError;
      },
      subscribeToMore: {
        document: workItemTitleSubscription,
        variables() {
          return {
            issuableId: this.workItemId,
          };
        },
      },
    },
  },
  computed: {
    workItemLoading() {
      return this.$apollo.queries.workItem.loading;
    },
    workItemType() {
      return this.workItem.workItemType?.name;
    },
    canUpdate() {
      return this.workItem?.userPermissions?.updateWorkItem;
    },
    canDelete() {
      return this.workItem?.userPermissions?.deleteWorkItem;
    },
    workItemsMvc2Enabled() {
      return this.glFeatures.workItemsMvc2;
    },
    hasDescriptionWidget() {
      return this.workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_DESCRIPTION);
    },
    workItemAssignees() {
      return this.workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_ASSIGNEES);
    },
    workItemLabels() {
      return this.workItem?.mockWidgets?.find((widget) => widget.type === WIDGET_TYPE_LABELS);
    },
    workItemWeight() {
      return this.workItem?.mockWidgets?.find((widget) => widget.type === WIDGET_TYPE_WEIGHT);
    },
    workItemHierarchy() {
      return this.workItem?.widgets?.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY);
    },
    parentWorkItem() {
      return this.workItemHierarchy?.parent;
    },
    parentUrl() {
      return `../../issues/${this.parentWorkItem?.iid}`;
    },
  },
};
</script>

<template>
  <section class="gl-pt-5">
    <gl-alert v-if="error" variant="danger" @dismiss="error = undefined">
      {{ error }}
    </gl-alert>

    <div v-if="workItemLoading" class="gl-max-w-26 gl-py-5">
      <gl-skeleton-loader :height="65" :width="240">
        <rect width="240" height="20" x="5" y="0" rx="4" />
        <rect width="100" height="20" x="5" y="45" rx="4" />
      </gl-skeleton-loader>
    </div>
    <template v-else>
      <div class="gl-display-flex gl-align-items-center">
        <ul
          v-if="parentWorkItem"
          class="list-unstyled gl-display-flex gl-mr-auto"
          data-testid="work-item-parent"
        >
          <li class="gl-ml-n4">
            <gl-button icon="issues" category="tertiary" :href="parentUrl">{{
              parentWorkItem.title
            }}</gl-button>
            <gl-icon name="chevron-right" :size="16" />
          </li>
          <li class="gl-px-4 gl-py-3 gl-line-height-0">
            <gl-icon name="task-done" />
            {{ workItemType }}
          </li>
        </ul>
        <span
          v-else
          class="gl-font-weight-bold gl-text-secondary gl-mr-auto"
          data-testid="work-item-type"
          >{{ workItemType }}</span
        >
        <work-item-actions
          :work-item-id="workItem.id"
          :can-delete="canDelete"
          @deleteWorkItem="$emit('deleteWorkItem')"
          @error="error = $event"
        />
        <gl-button
          v-if="isModal"
          category="tertiary"
          data-testid="work-item-close"
          icon="close"
          :aria-label="__('Close')"
          @click="$emit('close')"
        />
      </div>
      <work-item-title
        :work-item-id="workItem.id"
        :work-item-title="workItem.title"
        :work-item-type="workItemType"
        :work-item-parent-id="workItemParentId"
        @error="error = $event"
      />
      <work-item-state
        :work-item="workItem"
        :work-item-parent-id="workItemParentId"
        @error="error = $event"
      />
      <template v-if="workItemsMvc2Enabled">
        <work-item-assignees
          v-if="workItemAssignees"
          :work-item-id="workItem.id"
          :assignees="workItemAssignees.assignees.nodes"
          :allows-multiple-assignees="workItemAssignees.allowsMultipleAssignees"
          @error="error = $event"
        />
        <work-item-labels
          v-if="workItemLabels"
          :work-item-id="workItem.id"
          :can-update="canUpdate"
          @error="error = $event"
        />
        <work-item-weight
          v-if="workItemWeight"
          class="gl-mb-5"
          :can-update="canUpdate"
          :weight="workItemWeight.weight"
          :work-item-id="workItem.id"
          :work-item-type="workItemType"
        />
      </template>
      <work-item-description
        v-if="hasDescriptionWidget"
        :work-item-id="workItem.id"
        class="gl-pt-5"
        @error="error = $event"
      />
    </template>
  </section>
</template>
