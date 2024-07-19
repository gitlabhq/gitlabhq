<script>
import { GlLoadingIcon, GlIcon, GlButton, GlTooltipDirective, GlModalDirective } from '@gitlab/ui';

import { s__, __ } from '~/locale';

import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { WIDGET_TYPE_DEVELOPMENT } from '~/work_items/constants';

import WorkItemDevelopmentRelationshipList from './work_item_development_relationship_list.vue';

export default {
  components: {
    GlLoadingIcon,
    GlIcon,
    GlButton,
    WorkItemDevelopmentRelationshipList,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  props: {
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    workItemFullPath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    workItemDevelopment: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.workItemFullPath,
          iid: this.workItemIid,
        };
      },
      update(data) {
        return (
          data.workspace?.workItem?.widgets?.find(
            (widget) => widget.type === WIDGET_TYPE_DEVELOPMENT,
          ) || {}
        );
      },
      skip() {
        return !this.workItemIid;
      },
      error(e) {
        this.$emit('error', this.$options.i18n.fetchError);
        this.error = e.message || this.$options.i18n.fetchError;
      },
    },
  },
  data() {
    return {
      error: '',
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.workItemDevelopment.loading;
    },
    linkedMergeRequests() {
      return this.workItemDevelopment?.closingMergeRequests?.nodes || [];
    },
    isEmptyRelatedWorkItems() {
      return !this.error && this.linkedMergeRequests.length === 0;
    },
  },
  createMRModalId: 'create-merge-request-modal',
  i18n: {
    development: s__('WorkItem|Development'),
    fetchError: s__('WorkItem|Something went wrong when fetching items. Please refresh this page.'),
    createMergeRequest: __('Create merge request'),
    createBranch: __('Create branch'),
  },
};
</script>
<template>
  <div>
    <div class="gl-flex gl-items-center gl-gap-3 gl-justify-between">
      <h3 class="gl-mb-0! gl-heading-5" data-testid="dev-widget-label">
        {{ $options.i18n.development }}
      </h3>
      <gl-button
        v-if="canUpdate"
        v-gl-modal="$options.createMRModalId"
        v-gl-tooltip.top
        category="tertiary"
        size="small"
        data-testid="add-item"
        :title="__('Add branch or merge request')"
        :aria-label="__('Add branch or merge request')"
      >
        <gl-icon name="plus" class="gl-text-gray-900!" />
      </gl-button>
    </div>
    <gl-loading-icon v-if="isLoading" class="gl-my-2" />
    <template v-else-if="isEmptyRelatedWorkItems">
      <span v-if="!canUpdate" class="gl-text-secondary">{{ __('None') }}</span>
      <template v-else>
        <gl-button category="secondary" size="small" data-testid="create-mr-button">{{
          $options.i18n.createMergeRequest
        }}</gl-button>
        <gl-button category="tertiary" size="small" data-testid="create-branch-button">{{
          $options.i18n.createBranch
        }}</gl-button>
      </template>
    </template>
    <work-item-development-relationship-list v-else :work-item-dev-widget="workItemDevelopment" />
  </div>
</template>
