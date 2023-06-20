<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import ResourceParentLink from '../resource_parent_link.vue';
import ContributionEventBase from './contribution_event_base.vue';

export default {
  name: 'ContributionEventJoined',
  i18n: {
    message: s__('ContributionEvent|Joined project %{resourceParentLink}.'),
  },
  components: { ContributionEventBase, ResourceParentLink, GlSprintf },
  props: {
    /**
     * Expected format
     * {
     *   created_at: string;
     *   action: "joined"
     *   author: {
     *     id: number;
     *     username: string;
     *     name: string;
     *     state: string;
     *     avatar_url: string;
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
  <contribution-event-base :event="event" icon-name="users">
    <gl-sprintf :message="$options.i18n.message">
      <template #resourceParentLink>
        <resource-parent-link :event="event" />
      </template>
    </gl-sprintf>
  </contribution-event-base>
</template>
