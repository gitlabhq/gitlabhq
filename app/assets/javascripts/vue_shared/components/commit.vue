<script>
import { isString, isEmpty } from 'lodash';
import { GlTooltipDirective, GlLink } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import UserAvatarLink from './user_avatar/user_avatar_link.vue';
import Icon from './icon.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    UserAvatarLink,
    Icon,
    GlLink,
    TooltipOnTruncate,
  },
  props: {
    /**
     * Indicates the existence of a tag.
     * Used to render the correct icon, if true will render `fa-tag` icon,
     * if false will render a svg sprite fork icon
     */
    tag: {
      type: Boolean,
      required: false,
      default: false,
    },
    /**
     * If provided is used to render the branch name and url.
     * Should contain the following properties:
     * name
     * ref_url
     */
    commitRef: {
      type: Object,
      required: false,
      default: () => ({}),
    },

    /**
     * If provided, is used the render the MR IID and link
     * in place of the branch name.  Must contains the
     * following properties:
     *   - iid (number)
     *   - path (non-empty string)
     *
     * May optionally contain the following properties:
     *   - title (string): used in a tooltip if provided
     *
     * Any additional properties are ignored.
     */
    mergeRequestRef: {
      type: Object,
      required: false,
      default: undefined,
      validator: ref =>
        ref === undefined || (Number.isFinite(ref.iid) && isString(ref.path) && !isEmpty(ref.path)),
    },

    /**
     * Used to link to the commit sha.
     */
    commitUrl: {
      type: String,
      required: false,
      default: '',
    },

    /**
     * Used to show the commit short sha that links to the commit url.
     */
    shortSha: {
      type: String,
      required: false,
      default: '',
    },
    /**
     * If provided shows the commit tile.
     */
    title: {
      type: String,
      required: false,
      default: '',
    },
    /**
     * If provided renders information about the author of the commit.
     * When provided should include:
     * `avatar_url` to render the avatar icon
     * `web_url` to link to user profile
     * `username` to render alt and title tags
     */
    author: {
      type: Object,
      required: false,
      default: () => ({}),
    },

    /**
     * Indicates whether or not to show the branch/MR ref info
     */
    showRefInfo: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    /**
     * Determines if we shoud render the ref info section based
     */
    shouldShowRefInfo() {
      return this.showRefInfo && (this.commitRef || this.mergeRequestRef);
    },

    /**
     * Used to verify if all the properties needed to render the commit
     * author section were provided.
     *
     * @returns {Boolean}
     */
    hasAuthor() {
      return this.author && this.author.avatar_url && this.author.path && this.author.username;
    },
    /**
     * If information about the author is provided will return a string
     * to be rendered as the alt attribute of the img tag.
     *
     * @returns {String}
     */
    userImageAltDescription() {
      return this.author && this.author.username
        ? sprintf(__("%{username}'s avatar"), { username: this.author.username })
        : null;
    },
  },
};
</script>
<template>
  <div class="branch-commit cgray">
    <template v-if="shouldShowRefInfo">
      <div class="icon-container">
        <icon v-if="tag" name="tag" />
        <icon v-else-if="mergeRequestRef" name="git-merge" />
        <icon v-else name="branch" />
      </div>

      <gl-link
        v-if="mergeRequestRef"
        v-gl-tooltip
        :href="mergeRequestRef.path"
        :title="mergeRequestRef.title"
        class="ref-name"
        >{{ mergeRequestRef.iid }}</gl-link
      >
      <gl-link
        v-else
        v-gl-tooltip
        :href="commitRef.ref_url"
        :title="commitRef.name"
        class="ref-name"
        >{{ commitRef.name }}</gl-link
      >
    </template>
    <icon name="commit" class="commit-icon js-commit-icon" />

    <gl-link :href="commitUrl" class="commit-sha mr-0">{{ shortSha }}</gl-link>

    <div class="commit-title">
      <span v-if="title" class="flex-truncate-parent">
        <user-avatar-link
          v-if="hasAuthor"
          :link-href="author.path"
          :img-src="author.avatar_url"
          :img-alt="userImageAltDescription"
          :tooltip-text="author.username"
          class="avatar-image-container text-decoration-none"
        />
        <tooltip-on-truncate :title="title" class="flex-truncate-child">
          <gl-link :href="commitUrl" class="commit-row-message cgray">{{ title }}</gl-link>
        </tooltip-on-truncate>
      </span>
      <span v-else>{{ __("Can't find HEAD commit for this branch") }}</span>
    </div>
  </div>
</template>
