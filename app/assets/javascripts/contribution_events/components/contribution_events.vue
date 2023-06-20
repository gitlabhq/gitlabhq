<script>
import EmptyComponent from '~/vue_shared/components/empty_component';
import { EVENT_TYPE_APPROVED } from '../constants';
import ContributionEventApproved from './contribution_event/contribution_event_approved.vue';

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

        default:
          return EmptyComponent;
      }
    },
  },
};
</script>

<template>
  <ul class="gl-list-style-none gl-p-0">
    <component
      :is="eventComponent(event.action)"
      v-for="(event, index) in events"
      :key="index"
      :event="event"
    />
  </ul>
</template>
