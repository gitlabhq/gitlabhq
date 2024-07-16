<script>
import { GlIcon, GlPopover, GlBadge, GlSprintf } from '@gitlab/ui';

import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import { formatAncestors } from '../../utils';
import workItemAncestorsQuery from '../../graphql/work_item_ancestors.query.graphql';
import workItemAncestorsUpdatedSubscription from '../../graphql/work_item_ancestors.subscription.graphql';
import WorkItemStateBadge from '../work_item_state_badge.vue';
import DisclosureHierarchy from './disclosure_hierarchy.vue';

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
        return formatAncestors(data.workItem);
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
      <gl-popover triggers="hover focus" placement="bottom" :target="itemId">
        <template #title>
          <div>
            <gl-badge variant="muted">{{ $options.i18n.ancestorLabel }}</gl-badge>
            <div class="gl-pt-3">
              {{ item.title }}
            </div>
          </div>
        </template>
        <div class="gl-pb-3 gl-text-secondary">
          <gl-icon v-if="item.icon" :name="item.icon" />
          {{ item.reference }}
        </div>
        <work-item-state-badge v-if="item.state" :work-item-state="item.state" />
        <span class="gl-align-middle gl-text-secondary">
          <gl-sprintf v-if="item.createdAt" :message="__('Created %{timeAgo}')">
            <template #timeAgo>
              <time-ago-tooltip :time="item.createdAt" />
            </template>
          </gl-sprintf>
        </span>
      </gl-popover>
    </template>
  </disclosure-hierarchy>
</template>
