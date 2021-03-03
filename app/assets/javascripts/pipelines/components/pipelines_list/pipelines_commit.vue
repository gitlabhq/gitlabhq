<script>
import { CHILD_VIEW } from '~/pipelines/constants';
import CommitComponent from '~/vue_shared/components/commit.vue';

export default {
  components: {
    CommitComponent,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
    viewType: {
      type: String,
      required: true,
    },
  },
  computed: {
    commitAuthor() {
      let commitAuthorInformation;

      if (!this.pipeline || !this.pipeline.commit) {
        return null;
      }

      // 1. person who is an author of a commit might be a GitLab user
      if (this.pipeline.commit.author) {
        // 2. if person who is an author of a commit is a GitLab user
        // they can have a GitLab avatar
        if (this.pipeline.commit.author.avatar_url) {
          commitAuthorInformation = this.pipeline.commit.author;

          // 3. If GitLab user does not have avatar, they might have a Gravatar
        } else if (this.pipeline.commit.author_gravatar_url) {
          commitAuthorInformation = {
            ...this.pipeline.commit.author,
            avatar_url: this.pipeline.commit.author_gravatar_url,
          };
        }
        // 4. If committer is not a GitLab User, they can have a Gravatar
      } else {
        commitAuthorInformation = {
          avatar_url: this.pipeline.commit.author_gravatar_url,
          path: `mailto:${this.pipeline.commit.author_email}`,
          username: this.pipeline.commit.author_name,
        };
      }

      return commitAuthorInformation;
    },
    commitTag() {
      return this.pipeline?.ref?.tag;
    },
    commitRef() {
      return this.pipeline?.ref;
    },
    commitUrl() {
      return this.pipeline?.commit?.commit_path;
    },
    commitShortSha() {
      return this.pipeline?.commit?.short_id;
    },
    commitTitle() {
      return this.pipeline?.commit?.title;
    },
    isChildView() {
      return this.viewType === CHILD_VIEW;
    },
  },
};
</script>

<template>
  <commit-component
    :tag="commitTag"
    :commit-ref="commitRef"
    :commit-url="commitUrl"
    :merge-request-ref="pipeline.merge_request"
    :short-sha="commitShortSha"
    :title="commitTitle"
    :author="commitAuthor"
    :show-ref-info="!isChildView"
  />
</template>
