<script>
/* eslint-disable vue/no-v-html */
import { GlTooltipDirective, GlLink, GlButton, GlButtonGroup, GlLoadingIcon } from '@gitlab/ui';
import defaultAvatarUrl from 'images/no_avatar.png';
import pathLastCommitQuery from 'shared_queries/repository/path_last_commit.query.graphql';
import { sprintf, s__ } from '~/locale';
import UserAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import TimeagoTooltip from '../../vue_shared/components/time_ago_tooltip.vue';
import CiIcon from '../../vue_shared/components/ci_icon.vue';
import ClipboardButton from '../../vue_shared/components/clipboard_button.vue';
import getRefMixin from '../mixins/get_ref';
import projectPathQuery from '../queries/project_path.query.graphql';

export default {
  components: {
    UserAvatarLink,
    TimeagoTooltip,
    ClipboardButton,
    CiIcon,
    GlButton,
    GlButtonGroup,
    GlLink,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [getRefMixin],
  apollo: {
    projectPath: {
      query: projectPathQuery,
    },
    commit: {
      query: pathLastCommitQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          ref: this.ref,
          path: this.currentPath.replace(/^\//, ''),
        };
      },
      update: data => {
        const pipelines = data.project?.repository?.tree?.lastCommit?.pipelines?.edges;

        return {
          ...data.project?.repository?.tree?.lastCommit,
          pipeline: pipelines?.length && pipelines[0].node,
        };
      },
      context: {
        isSingleRequest: true,
      },
      error(error) {
        throw error;
      },
    },
  },
  props: {
    currentPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      projectPath: '',
      commit: null,
      showDescription: false,
    };
  },
  computed: {
    statusTitle() {
      return sprintf(s__('PipelineStatusTooltip|Pipeline: %{ciStatus}'), {
        ciStatus: this.commit.pipeline.detailedStatus.text,
      });
    },
    isLoading() {
      return this.$apollo.queries.commit.loading;
    },
    showCommitId() {
      return this.commit?.sha?.substr(0, 8);
    },
  },
  watch: {
    currentPath() {
      this.commit = null;
    },
  },
  methods: {
    toggleShowDescription() {
      this.showDescription = !this.showDescription;
    },
  },
  defaultAvatarUrl,
};
</script>

<template>
  <div class="info-well d-none d-sm-flex project-last-commit commit p-3">
    <gl-loading-icon v-if="isLoading" size="md" color="dark" class="m-auto" />
    <template v-else-if="commit">
      <user-avatar-link
        v-if="commit.author"
        :link-href="commit.author.webPath"
        :img-src="commit.author.avatarUrl"
        :img-size="40"
        class="avatar-cell"
      />
      <span v-else class="avatar-cell user-avatar-link">
        <img
          :src="commit.authorGravatar || $options.defaultAvatarUrl"
          width="40"
          height="40"
          class="avatar s40"
        />
      </span>
      <div class="commit-detail flex-list">
        <div class="commit-content qa-commit-content">
          <gl-link
            :href="commit.webPath"
            :class="{ 'font-italic': !commit.message }"
            class="commit-row-message item-title"
            v-html="commit.titleHtml"
          />
          <gl-button
            v-if="commit.descriptionHtml"
            :class="{ open: showDescription }"
            :aria-label="__('Show commit description')"
            class="text-expander gl-vertical-align-bottom!"
            icon="ellipsis_h"
            @click="toggleShowDescription"
          />
          <div class="committer">
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
            {{ s__('LastCommit|authored') }}
            <timeago-tooltip :time="commit.authoredDate" tooltip-placement="bottom" />
          </div>
          <pre
            v-if="commit.descriptionHtml"
            :class="{ 'd-block': showDescription }"
            class="commit-row-description gl-mb-3"
            v-html="commit.descriptionHtml"
          ></pre>
        </div>
        <div class="commit-actions flex-row">
          <div v-if="commit.signatureHtml" v-html="commit.signatureHtml"></div>
          <div v-if="commit.pipeline" class="ci-status-link">
            <gl-link
              v-gl-tooltip.left
              :href="commit.pipeline.detailedStatus.detailsPath"
              :title="statusTitle"
              class="js-commit-pipeline"
            >
              <ci-icon
                :status="commit.pipeline.detailedStatus"
                :size="24"
                :aria-label="statusTitle"
              />
            </gl-link>
          </div>
          <gl-button-group class="gl-ml-4 js-commit-sha-group">
            <gl-button
              label
              class="gl-font-monospace"
              data-testid="last-commit-id-label"
              v-text="showCommitId"
            />
            <clipboard-button
              :text="commit.sha"
              :title="__('Copy commit SHA')"
              class="input-group-text"
            />
          </gl-button-group>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.commit {
  min-height: 4.75rem;
}
</style>
