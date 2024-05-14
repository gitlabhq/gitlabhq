<script>
import EmptyComponent from '~/vue_shared/components/empty_component';
import {
  EVENT_TYPE_APPROVED,
  EVENT_TYPE_EXPIRED,
  EVENT_TYPE_JOINED,
  EVENT_TYPE_LEFT,
  EVENT_TYPE_PUSHED,
  EVENT_TYPE_PRIVATE,
  EVENT_TYPE_MERGED,
  EVENT_TYPE_CREATED,
  EVENT_TYPE_CLOSED,
  EVENT_TYPE_REOPENED,
  EVENT_TYPE_COMMENTED,
  EVENT_TYPE_UPDATED,
  EVENT_TYPE_DESTROYED,
} from '../constants';
import ContributionEventApproved from './contribution_event/contribution_event_approved.vue';
import ContributionEventExpired from './contribution_event/contribution_event_expired.vue';
import ContributionEventJoined from './contribution_event/contribution_event_joined.vue';
import ContributionEventLeft from './contribution_event/contribution_event_left.vue';
import ContributionEventPushed from './contribution_event/contribution_event_pushed.vue';
import ContributionEventPrivate from './contribution_event/contribution_event_private.vue';
import ContributionEventMerged from './contribution_event/contribution_event_merged.vue';
import ContributionEventCreated from './contribution_event/contribution_event_created.vue';
import ContributionEventClosed from './contribution_event/contribution_event_closed.vue';
import ContributionEventReopened from './contribution_event/contribution_event_reopened.vue';
import ContributionEventCommented from './contribution_event/contribution_event_commented.vue';
import ContributionEventUpdated from './contribution_event/contribution_event_updated.vue';
import ContributionEventDestroyed from './contribution_event/contribution_event_destroyed.vue';

export default {
  props: {
    /**
     * Expected format
     * {
     *   created_at: string;
     *   action:
     *     | "created"
     *     | "updated"
     *     | "closed"
     *     | "reopened"
     *     | "pushed"
     *     | "commented"
     *     | "merged"
     *     | "joined"
     *     | "left"
     *     | "destroyed"
     *     | "expired"
     *     | "approved"
     *     | "private";
     *   ref?: {
     *     type: "branch" | "tag";
     *     count: number;
     *     name: string;
     *     path: string;
     *     is_new: boolean;
     *     is_removed: boolean;
     *   };
     *   commit?: {
     *     truncated_sha: string;
     *     path: string;
     *     title: string;
     *     count: number;
     *     create_mr_path: string;
     *     from_truncated_sha?: string;
     *     to_truncated_sha?: string;
     *     compare_path?: string;
     *   };
     *   author: {
     *     id: number;
     *     username: string;
     *     name: string;
     *     state: string;
     *     avatar_url: string;
     *     web_url: string;
     *   };
     *   noteable?: {
     *     type: string;
     *     reference_link_text: string;
     *     web_url: string;
     *     first_line_in_markdown: string;
     *   };
     *   target?: {
     *     id: number;
     *     type:
     *       | "Issue"
     *       | "Milestone"
     *       | "MergeRequest"
     *       | "Note"
     *       | "Project"
     *       | "Snippet"
     *       | "User"
     *       | "WikiPage::Meta"
     *       | "DesignManagement::Design";
     *     title: string;
     *     issue_type?:
     *       | "issue"
     *       | "incident"
     *       | "test_case"
     *       | "requirement"
     *       | "task"
     *       | "objective"
     *       | "key_result";
     *     reference_link_text?: string;
     *     web_url: string;
     *   };
     *   resource_parent?: {
     *     type: "project" | "group";
     *     full_name: string;
     *     full_path: string;
     *     web_url: string;
     *     avatar_url: string;
     *   };
     * }[];
     */
    events: {
      type: Array,
      required: true,
    },
  },
  methods: {
    eventComponent(action) {
      switch (action) {
        case EVENT_TYPE_APPROVED:
          return ContributionEventApproved;

        case EVENT_TYPE_EXPIRED:
          return ContributionEventExpired;

        case EVENT_TYPE_JOINED:
          return ContributionEventJoined;

        case EVENT_TYPE_LEFT:
          return ContributionEventLeft;

        case EVENT_TYPE_PUSHED:
          return ContributionEventPushed;

        case EVENT_TYPE_PRIVATE:
          return ContributionEventPrivate;

        case EVENT_TYPE_MERGED:
          return ContributionEventMerged;

        case EVENT_TYPE_CREATED:
          return ContributionEventCreated;

        case EVENT_TYPE_CLOSED:
          return ContributionEventClosed;

        case EVENT_TYPE_REOPENED:
          return ContributionEventReopened;

        case EVENT_TYPE_COMMENTED:
          return ContributionEventCommented;

        case EVENT_TYPE_UPDATED:
          return ContributionEventUpdated;

        case EVENT_TYPE_DESTROYED:
          return ContributionEventDestroyed;

        default:
          return EmptyComponent;
      }
    },
  },
};
</script>

<template>
  <ul class="gl-list-none gl-p-0">
    <component
      :is="eventComponent(event.action)"
      v-for="(event, index) in events"
      :key="index"
      :event="event"
    />
  </ul>
</template>
