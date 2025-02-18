<!-- eslint-disable vue/multi-word-component-names -->
<script>
import {
  GlIcon,
  GlLink,
  GlBadge,
  GlSprintf,
  GlTooltipDirective as GlTooltip,
  GlTruncate,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import DeploymentStatusLink from './deployment_status_link.vue';
import Commit from './commit.vue';

export default {
  components: {
    ClipboardButton,
    Commit,
    DeploymentStatusLink,
    GlBadge,
    GlSprintf,
    GlIcon,
    GlLink,
    GlTruncate,
    TimelineEntryItem,
  },
  directives: {
    GlTooltip,
  },
  props: {
    deployment: {
      type: Object,
      required: true,
    },
    latest: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    status() {
      return this.deployment?.status;
    },
    isTag() {
      return this.deployment?.tag;
    },
    shortSha() {
      return this.commit?.shortId;
    },
    triggeredText() {
      if (this.user && this.displayTime) {
        return s__('Deployment|Triggered by %{username} on %{time}');
      }
      if (this.user && !this.displayTime) {
        return s__('Deployment|Triggered by %{username}');
      }
      if (this.displayTime && !this.user) {
        return s__('Deployment|Triggered on %{time}');
      }
      return '';
    },
    deploymentTime() {
      return this.deployment?.deployedAt || this.deployment?.createdAt;
    },
    displayTime() {
      if (!this.deploymentTime) return null;
      const dateTime = new Date(this.deploymentTime);
      return localeDateFormat.asDateTimeFull.format(dateTime);
    },
    createdAt() {
      return this.deployment?.createdAt;
    },
    commit() {
      return this.deployment?.commit;
    },
    commitPath() {
      return this.commit?.commitPath;
    },
    user() {
      return this.deployment?.user;
    },
    username() {
      return `@${this.user.username}`;
    },
    userPath() {
      return this.user?.path;
    },
    deployable() {
      return this.deployment?.deployable;
    },
    ref() {
      return this.deployment?.ref;
    },
    refName() {
      return this.ref?.name;
    },
    refPath() {
      return this.ref?.refPath;
    },
    needsApproval() {
      return this.deployment.pendingApprovalCount > 0;
    },
  },
  i18n: {
    latestBadge: s__('Deployment|Latest Deployed'),
    copyButton: __('Copy commit SHA'),
    commitSha: __('Commit SHA'),
    needsApproval: s__('Deployment|Needs Approval'),
    tag: s__('Deployment|Tag'),
  },
};
</script>
<template>
  <timeline-entry-item class="system-note gl-relative">
    <div
      class="system-note-dot gl-relative gl-float-left gl-ml-4 gl-mt-3 gl-h-3 gl-w-3 gl-rounded-full gl-border-2 gl-border-solid gl-border-subtle gl-bg-gray-900"
    ></div>
    <div class="gl-ml-7">
      <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-3">
        <deployment-status-link
          v-if="status"
          :deployment="deployment"
          :deployment-job="deployable"
          :status="status"
        />
        <gl-badge v-if="needsApproval" variant="warning">
          {{ $options.i18n.needsApproval }}
        </gl-badge>
        <gl-badge v-if="latest" variant="info">{{ $options.i18n.latestBadge }}</gl-badge>
      </div>
      <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-x-3">
        <commit v-if="commit" :commit="commit" class="gl-max-w-5/8" />
        <div
          v-if="shortSha"
          data-testid="deployment-commit-sha"
          class="gl-flex gl-items-center gl-font-monospace"
        >
          <gl-icon ref="deployment-commit-icon" name="commit" class="gl-mr-2" />
          <gl-link v-gl-tooltip :title="$options.i18n.commitSha" :href="commitPath">
            {{ shortSha }}
          </gl-link>
          <clipboard-button
            :text="shortSha"
            category="tertiary"
            :title="$options.i18n.copyButton"
            size="small"
          />
        </div>
        <div
          v-if="isTag"
          data-testid="deployment-tag"
          class="gl-flex gl-items-center gl-font-monospace"
        >
          <gl-icon ref="deployment-tag-icon" name="tag" class="gl-mr-2" />
          <gl-link v-gl-tooltip :title="$options.i18n.tag" :href="refPath">
            {{ refName }}
          </gl-link>
        </div>
      </div>
      <div v-if="triggeredText" class="gl-flex gl-flex-wrap gl-items-center gl-gap-x-2">
        <gl-sprintf :message="triggeredText">
          <template #username>
            <gl-link :href="userPath" data-testid="deployment-triggerer">
              <gl-truncate :text="username" with-tooltip />
            </gl-link>
          </template>
          <template #time>
            <span
              v-gl-tooltip
              class="gl-truncate-end gl-mr-2 gl-whitespace-nowrap"
              data-testid="deployment-timestamp"
              :title="displayTime"
            >
              {{ displayTime }}
            </span>
          </template>
        </gl-sprintf>
      </div>
    </div>
  </timeline-entry-item>
</template>
