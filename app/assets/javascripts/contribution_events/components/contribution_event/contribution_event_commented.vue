<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import {
  EVENT_COMMENTED_I18N,
  EVENT_COMMENTED_SNIPPET_I18N,
} from 'ee_else_ce/contribution_events/constants';
import { SNIPPET_NOTEABLE_TYPE, COMMIT_NOTEABLE_TYPE } from '~/notes/constants';
import SafeHtml from '~/vue_shared/directives/safe_html';
import ResourceParentLink from '../resource_parent_link.vue';
import ContributionEventBase from './contribution_event_base.vue';

export default {
  name: 'ContributionEventCommented',
  components: { ContributionEventBase, GlSprintf, GlLink, ResourceParentLink },
  directives: {
    SafeHtml,
  },
  props: {
    event: {
      type: Object,
      required: true,
    },
  },
  computed: {
    resourceParent() {
      return this.event.resource_parent;
    },
    noteable() {
      return this.event.noteable;
    },
    noteableType() {
      return this.noteable.type;
    },
    message() {
      if (this.noteableType === SNIPPET_NOTEABLE_TYPE) {
        return (
          EVENT_COMMENTED_SNIPPET_I18N[this.resourceParent?.type] ||
          EVENT_COMMENTED_SNIPPET_I18N.fallback
        );
      }

      return EVENT_COMMENTED_I18N[this.noteableType] || EVENT_COMMENTED_I18N.fallback;
    },
    noteableLinkClass() {
      if (this.noteableType === COMMIT_NOTEABLE_TYPE) {
        return ['gl-font-monospace'];
      }

      return [];
    },
  },
};
</script>

<template>
  <contribution-event-base :event="event" icon-name="comment">
    <gl-sprintf :message="message">
      <template #noteableLink>
        <gl-link :class="noteableLinkClass" :href="noteable.web_url">{{
          noteable.reference_link_text
        }}</gl-link>
      </template>
      <template #resourceParentLink>
        <resource-parent-link :event="event" />
      </template>
    </gl-sprintf>
    <template v-if="noteable.first_line_in_markdown" #additional-info>
      <div v-safe-html="noteable.first_line_in_markdown" class="md"></div>
    </template>
  </contribution-event-base>
</template>
