<script>
import { GlTooltipDirective, GlIcon, GlLink, GlButton } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import defaultAvatarUrl from 'images/no_avatar.png';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import getRefMixin from '../mixins/get_ref';

export default {
  components: {
    UserAvatarLink,
    TimeagoTooltip,
    GlIcon,
    GlButton,
    GlLink,
    UserAvatarImage,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  mixins: [getRefMixin],
  props: {
    commit: {
      type: Object,
      required: true,
    },
    historyUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return { showDescription: false };
  },
  computed: {
    commitDescription() {
      // Strip the newline at the beginning
      return this.commit?.descriptionHtml?.replace(/^&#x000A;/, '');
    },
    avatarLinkAltText() {
      return sprintf(__(`%{username}'s avatar`), { username: this.commit.authorName });
    },
    commitId() {
      return this.commit?.sha?.substr(0, 8);
    },
  },
  methods: {
    toggleShowDescription() {
      this.showDescription = !this.showDescription;
    },
  },
  defaultAvatarUrl,
  safeHtmlConfig: {
    ADD_TAGS: ['gl-emoji'],
  },
  i18n: {
    toggleCommitDescription: __('Toggle commit description'),
    authored: __('authored'),
  },
};
</script>

<template>
  <div class="well-segment !gl-px-4 !gl-py-3">
    <div class="gl-flex gl-flex-wrap gl-items-center gl-justify-between">
      <div class="gl-flex gl-items-center gl-gap-3 gl-text-sm">
        <user-avatar-link
          v-if="commit.author"
          :link-href="commit.author.webPath"
          :img-src="commit.author.avatarUrl"
          :img-alt="avatarLinkAltText"
          :img-size="32"
        />
        <user-avatar-image
          v-else
          :img-src="commit.authorGravatar || $options.defaultAvatarUrl"
          :size="32"
        />
        <gl-link
          :href="commit.webPath"
          :class="{ 'gl-italic': !commit.message }"
          class="commit-row-message item-title gl-line-clamp-1 gl-whitespace-normal !gl-break-all"
        >
          <gl-icon name="commit" />
          {{ commitId }}
        </gl-link>
        <timeago-tooltip
          :time="commit.authoredDate"
          tooltip-placement="bottom"
          class="gl-text-subtle"
        />
      </div>

      <div class="gl-flex gl-items-center gl-gap-3">
        <gl-button
          v-gl-tooltip
          :class="{ open: showDescription }"
          :title="$options.i18n.toggleCommitDescription"
          :aria-label="$options.i18n.toggleCommitDescription"
          :selected="showDescription"
          class="text-expander"
          icon="ellipsis_h"
          data-testid="text-expander"
          @click="toggleShowDescription"
        />
        <gl-button size="small" data-testid="collapsible-commit-history" :href="historyUrl">
          {{ __('History') }}
        </gl-button>
      </div>
    </div>
    <div v-if="showDescription" class="gl-mt-4">
      <p
        :class="{ 'gl-italic': !commit.message }"
        class="commit-row-message gl-line-clamp-1 gl-whitespace-normal !gl-break-all gl-font-bold"
      >
        {{ commit.titleHtml }}
      </p>
      <div class="committer gl-basis-full gl-truncate gl-text-sm" data-testid="committer">
        <gl-link
          v-if="commit.author"
          :href="commit.author.webPath"
          class="commit-author-link js-user-link"
        >
          {{ commit.author.name }}</gl-link
        >
        <template v-else>
          {{ commit.authorName }}
        </template>
        {{ $options.i18n.authored }}
        <timeago-tooltip :time="commit.authoredDate" tooltip-placement="bottom" />
      </div>
      <pre
        v-if="commit.descriptionHtml"
        v-safe-html:[$options.safeHtmlConfig]="commitDescription"
        class="commit-row-description gl-mb-3 gl-whitespace-pre-wrap"
      ></pre>
    </div>
  </div>
</template>
