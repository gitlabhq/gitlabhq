<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlTooltipDirective, GlLink, GlIcon } from '@gitlab/ui';
import { isString, isEmpty } from 'lodash';
import { __, sprintf } from '~/locale';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import UserAvatarLink from './user_avatar/user_avatar_link.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    UserAvatarLink,
    GlIcon,
    GlLink,
    TooltipOnTruncate,
  },
  props: {
    /**
     * Indicates the existence of a tag.
     * Used to render the correct GlIcon, if true will render `tag` GlIcon,
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
      validator: (ref) =>
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
     * Determines if we should render the ref info section based
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
    refUrl() {
      return this.commitRef.ref_url || this.commitRef.path;
    },
    tooltipTitle() {
      return this.mergeRequestRef ? this.mergeRequestRef.title : this.commitRef.name;
    },
  },
};
</script>
<template>
  <div class="branch-commit">
    <div data-testid="commit-title-container" class="gl-mb-2">
      <tooltip-on-truncate v-if="title" :title="title" class="gl-line-clamp-1">
        <gl-link :href="commitUrl" data-testid="commit-title">{{ title }}</gl-link>
      </tooltip-on-truncate>
      <span v-else data-testid="commit-no-title">{{
        __("Can't find HEAD commit for this branch")
      }}</span>
    </div>
    <div class="gl-mb-2">
      <div
        v-if="shouldShowRefInfo"
        class="gl-inline-block gl-rounded-base gl-bg-strong gl-px-2 gl-text-subtle"
        data-testid="commit-ref-info"
      >
        <gl-icon v-if="tag" name="tag" :size="12" variant="subtle" />
        <gl-icon v-else-if="mergeRequestRef" name="merge-request" :size="12" variant="subtle" />
        <gl-icon v-else name="branch" :size="12" variant="subtle" />

        <tooltip-on-truncate :title="tooltipTitle" truncate-target="child" placement="top">
          <gl-link
            v-if="mergeRequestRef"
            :href="mergeRequestRef.path"
            class="gl-text-gray-700"
            data-testid="ref-name"
          >
            {{ mergeRequestRef.iid }}
          </gl-link>
          <gl-link v-else :href="refUrl" class="gl-text-gray-700" data-testid="ref-name">
            {{ commitRef.name }}
          </gl-link>
        </tooltip-on-truncate>
      </div>

      <div class="gl-inline-block gl-rounded-base gl-bg-strong gl-px-2 gl-text-sm gl-text-default">
        <gl-icon name="commit" class="js-commit-icon" :size="12" />
        <gl-link :href="commitUrl" class="gl-text-gray-700" data-testid="commit-sha">{{
          shortSha
        }}</gl-link>
      </div>

      <user-avatar-link
        v-if="hasAuthor"
        :link-href="author.path"
        :img-src="author.avatar_url"
        :img-alt="userImageAltDescription"
        :tooltip-text="author.username"
        :img-size="16"
        class="avatar-image-container text-decoration-none"
        img-css-classes="gl-mr-3"
      />
    </div>
  </div>
</template>
