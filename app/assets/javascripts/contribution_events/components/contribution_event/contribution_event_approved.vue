<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import TargetLink from '../target_link.vue';
import ResourceParentLink from '../resource_parent_link.vue';
import ContributionEventBase from './contribution_event_base.vue';

export default {
  name: 'ContributionEventApproved',
  i18n: {
    message: s__(
      'ContributionEvent|Approved merge request %{targetLink} in %{resourceParentLink}.',
    ),
  },
  components: { ContributionEventBase, GlSprintf, TargetLink, ResourceParentLink },
  props: {
    /**
     * Expected format
     * {
     *   created_at: string;
     *   action: "approved"
     *   author: {
     *     id: number;
     *     username: string;
     *     name: string;
     *     state: string;
     *     avatar_url: string;
     *     web_url: string;
     *   };
     *   target: {
     *     id: number;
     *     type: "MergeRequest"
     *     title: string;
     *     reference_link_text: string;
     *     web_url: string;
     *   };
     *   resource_parent: {
     *     type: "project";
     *     full_name: string;
     *     full_path: string;
     *     web_url: string;
     *     avatar_url: string;
     *   };
     * };
     */
    event: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <contribution-event-base :event="event" icon-name="approval-solid" icon-class="gl-text-green-500">
    <gl-sprintf :message="$options.i18n.message">
      <template #targetLink>
        <target-link :event="event" />
      </template>
      <template #resourceParentLink>
        <resource-parent-link :event="event" />
      </template>
    </gl-sprintf>
  </contribution-event-base>
</template>
