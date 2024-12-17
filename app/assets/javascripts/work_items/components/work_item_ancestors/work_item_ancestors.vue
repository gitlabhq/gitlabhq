<script>
import { GlIcon, GlPopover, GlBadge, GlSprintf } from '@gitlab/ui';

import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import { findHierarchyWidgets, formatAncestors } from '../../utils';
import workItemAncestorsQuery from '../../graphql/work_item_ancestors.query.graphql';
import workItemAncestorsUpdatedSubscription from '../../graphql/work_item_ancestors.subscription.graphql';
import WorkItemStateBadge from '../work_item_state_badge.vue';
import DisclosureHierarchy from './disclosure_hierarchy.vue';

export const ANCESTOR_NOT_AVAILABLE = {
  title: s__('WorkItems|Ancestors not available'),
  ancestorNotAvailable: true,
  icon: 'eye-slash',
};

export default {
  i18n: {
    ancestorLabel: s__('WorkItem|Ancestor'),
    ancestorsTooltipLabel: s__('WorkItem|Show all ancestors'),
  },
  components: {
    GlIcon,
    GlPopover,
    GlBadge,
    GlSprintf,
    TimeAgoTooltip,
    WorkItemStateBadge,
    DisclosureHierarchy,
  },
  props: {
    workItem: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      ancestors: [],
    };
  },
  apollo: {
    ancestors: {
      query: workItemAncestorsQuery,
      variables() {
        return {
          id: this.workItem.id,
        };
      },
      update(data) {
        const formattedAncestors = formatAncestors(data.workItem).flatMap((ancestor) => {
          const ancestorHierarchyWidget = findHierarchyWidgets(ancestor.widgets);
          // Condition is to check if it `hasParent` is true and the parent object is null  i.e, inaccessible
          // then add "ancestor is not available" with other parents
          return ancestorHierarchyWidget?.hasParent && !ancestorHierarchyWidget?.parent
            ? [ANCESTOR_NOT_AVAILABLE, ancestor]
            : [ancestor];
        });

        // If the work item has a parent at root level but the parent object is null i.e, inaccessible
        // then add "ancestor is not available" as the only item
        const widgets = findHierarchyWidgets(data.workItem?.widgets);
        if (formattedAncestors.length === 0 && widgets?.hasParent && !widgets?.parent) {
          formattedAncestors.push(ANCESTOR_NOT_AVAILABLE);
        }
        return formattedAncestors;
      },
      skip() {
        return !this.workItem.id;
      },
      error(error) {
        createAlert({
          message: s__('Hierarchy|Something went wrong while fetching ancestors.'),
          captureError: true,
          error,
        });
      },
      subscribeToMore: {
        document: workItemAncestorsUpdatedSubscription,
        variables() {
          return {
            id: this.workItem.id,
          };
        },
        skip() {
          return !this.workItem?.id;
        },
      },
    },
  },
};
</script>

<template>
  <disclosure-hierarchy
    v-if="ancestors.length > 0"
    :items="ancestors"
    :with-ellipsis="ancestors.length > 2"
    :ellipsis-tooltip-label="$options.i18n.ancestorsTooltipLabel"
  >
    <template #default="{ item, itemId }">
      <gl-popover
        v-if="!item.ancestorNotAvailable"
        triggers="hover focus"
        placement="bottom"
        :target="itemId"
      >
        <template #title>
          <div>
            <gl-badge variant="muted">{{ $options.i18n.ancestorLabel }}</gl-badge>
            <div class="gl-pt-3">
              {{ item.title }}
            </div>
          </div>
        </template>
        <div class="gl-pb-3 gl-text-subtle">
          <gl-icon v-if="item.icon" :name="item.icon" variant="subtle" />
          {{ item.reference }}
        </div>
        <work-item-state-badge v-if="item.state" :work-item-state="item.state" />
        <span class="gl-align-middle gl-text-subtle">
          <gl-sprintf v-if="item.createdAt" :message="__('Created %{timeAgo}')">
            <template #timeAgo>
              <time-ago-tooltip :time="item.createdAt" />
            </template>
          </gl-sprintf>
        </span>
      </gl-popover>
      <gl-popover v-else triggers="hover focus" placement="bottom" :target="itemId">
        <span>{{
          s__(`WorkItem|You don't have the necessary permission to view the ancestors.`)
        }}</span>
      </gl-popover>
    </template>
  </disclosure-hierarchy>
</template>
