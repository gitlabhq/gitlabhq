<script>
  import commitIconSvg from 'icons/_icon_commit.svg';
  import userAvatarLink from './user_avatar/user_avatar_link.vue';
  import tooltip from '../directives/tooltip';
  import icon from '../../vue_shared/components/icon.vue';

  export default {
    directives: {
      tooltip,
    },
    components: {
      userAvatarLink,
      icon,
    },
    props: {
      /**
       * Indicates the existance of a tag.
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
      showBranch: {
        type: Boolean,
        required: false,
        default: true,
      },
    },
    computed: {
      /**
       * Used to verify if all the properties needed to render the commit
       * ref section were provided.
       *
       * @returns {Boolean}
       */
      hasCommitRef() {
        return this.commitRef && this.commitRef.name && this.commitRef.ref_url;
      },
      /**
       * Used to verify if all the properties needed to render the commit
       * author section were provided.
       *
       * @returns {Boolean}
       */
      hasAuthor() {
        return this.author &&
          this.author.avatar_url &&
          this.author.path &&
          this.author.username;
      },
      /**
       * If information about the author is provided will return a string
       * to be rendered as the alt attribute of the img tag.
       *
       * @returns {String}
       */
      userImageAltDescription() {
        return this.author &&
          this.author.username ? `${this.author.username}'s avatar` : null;
      },
    },
    created() {
      this.commitIconSvg = commitIconSvg;
    },
  };
</script>
<template>
  <div class="branch-commit">
    <template v-if="hasCommitRef && showBranch">
      <div class="icon-container">
        <i
          v-if="tag"
          class="fa fa-tag"
          aria-hidden="true"
        >
        </i>
        <icon
          v-if="!tag"
          name="fork"
        />
      </div>

      <a
        class="ref-name"
        :href="commitRef.ref_url"
        v-tooltip
        data-container="body"
        :title="commitRef.name"
      >
        {{ commitRef.name }}
      </a>
    </template>
    <div
      v-html="commitIconSvg"
      class="commit-icon js-commit-icon"
    >
    </div>

    <a
      class="commit-sha"
      :href="commitUrl"
    >
      {{ shortSha }}
    </a>

    <div class="commit-title flex-truncate-parent">
      <span
        v-if="title"
        class="flex-truncate-child"
      >
        <user-avatar-link
          v-if="hasAuthor"
          class="avatar-image-container"
          :link-href="author.path"
          :img-src="author.avatar_url"
          :img-alt="userImageAltDescription"
          :tooltip-text="author.username"
        />
        <a
          class="commit-row-message"
          :href="commitUrl"
        >
          {{ title }}
        </a>
      </span>
      <span v-else>
        Can't find HEAD commit for this branch
      </span>
    </div>
  </div>
</template>
