<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { PUSH_EVENT_REF_TYPE_BRANCH, PUSH_EVENT_REF_TYPE_TAG } from '../../constants';
import ResourceParentLink from '../resource_parent_link.vue';
import ContributionEventBase from './contribution_event_base.vue';

export default {
  name: 'ContributionEventPushed',
  i18n: {
    new: {
      [PUSH_EVENT_REF_TYPE_BRANCH]: s__(
        'ContributionEvent|Pushed a new branch %{refLink} in %{resourceParentLink}.',
      ),
      [PUSH_EVENT_REF_TYPE_TAG]: s__(
        'ContributionEvent|Pushed a new tag %{refLink} in %{resourceParentLink}.',
      ),
    },
    removed: {
      [PUSH_EVENT_REF_TYPE_BRANCH]: s__(
        'ContributionEvent|Deleted branch %{refLink} in %{resourceParentLink}.',
      ),
      [PUSH_EVENT_REF_TYPE_TAG]: s__(
        'ContributionEvent|Deleted tag %{refLink} in %{resourceParentLink}.',
      ),
    },
    pushed: {
      [PUSH_EVENT_REF_TYPE_BRANCH]: s__(
        'ContributionEvent|Pushed to branch %{refLink} in %{resourceParentLink}.',
      ),
      [PUSH_EVENT_REF_TYPE_TAG]: s__(
        'ContributionEvent|Pushed to tag %{refLink} in %{resourceParentLink}.',
      ),
    },
    multipleCommits: s__(
      'ContributionEvent|…and %{count} more commits. %{linkStart}Compare%{linkEnd}.',
    ),
  },
  components: { ContributionEventBase, GlSprintf, GlLink, ResourceParentLink },
  props: {
    event: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ref() {
      return this.event.ref;
    },
    commit() {
      return this.event.commit;
    },
    message() {
      if (this.ref.is_new) {
        return this.$options.i18n.new[this.ref.type];
      }
      if (this.ref.is_removed) {
        return this.$options.i18n.removed[this.ref.type];
      }

      return this.$options.i18n.pushed[this.ref.type];
    },
    iconName() {
      if (this.ref.is_removed) {
        return 'remove';
      }

      return 'commit';
    },
    hasMultipleCommits() {
      return this.commit.count > 1;
    },
  },
};
</script>

<template>
  <contribution-event-base :event="event" :icon-name="iconName">
    <gl-sprintf :message="message">
      <template #refLink>
        <gl-link v-if="ref.path" :href="ref.path" class="gl-font-monospace">{{ ref.name }}</gl-link>
        <span v-else class="gl-font-monospace">{{ ref.name }}</span>
      </template>
      <template #resourceParentLink>
        <resource-parent-link :event="event" />
      </template>
    </gl-sprintf>
    <template v-if="!ref.is_removed" #additional-info>
      <div>
        <gl-link :href="commit.path" class="gl-font-monospace">{{ commit.truncated_sha }}</gl-link>
        <template v-if="commit.title">
          &middot;
          <span>{{ commit.title }}</span>
        </template>
      </div>
      <div v-if="hasMultipleCommits" class="gl-mt-2">
        <gl-sprintf :message="$options.i18n.multipleCommits">
          <template #count>{{ commit.count - 1 }}</template>
          <template #link="{ content }">
            <gl-link :href="commit.compare_path"
              >{{ content }}
              <span class="gl-font-monospace"
                >{{ commit.from_truncated_sha }}…{{ commit.to_truncated_sha }}</span
              ></gl-link
            >
          </template>
        </gl-sprintf>
      </div>
    </template>
  </contribution-event-base>
</template>
