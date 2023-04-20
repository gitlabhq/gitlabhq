<script>
import { GlTooltipDirective, GlLink, GlButton, GlButtonGroup, GlLoadingIcon } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import defaultAvatarUrl from 'images/no_avatar.png';
import pathLastCommitQuery from 'shared_queries/repository/path_last_commit.query.graphql';
import { sprintf, s__ } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import SignatureBadge from '~/commit/components/signature_badge.vue';
import getRefMixin from '../mixins/get_ref';
import projectPathQuery from '../queries/project_path.query.graphql';
import eventHub from '../event_hub';
import { FORK_UPDATED_EVENT } from '../constants';

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
    UserAvatarImage,
    SignatureBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
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
      update: (data) => {
        const lastCommit = data.project?.repository?.paginatedTree?.nodes[0]?.lastCommit;
        const pipelines = lastCommit?.pipelines?.edges;

        return {
          ...lastCommit,
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
    commitDescription() {
      // Strip the newline at the beginning
      return this.commit?.descriptionHtml?.replace(/^&#x000A;/, '');
    },
  },
  watch: {
    currentPath() {
      this.commit = null;
    },
  },
  mounted() {
    eventHub.$on(FORK_UPDATED_EVENT, this.refetchLastCommit);
  },
  beforeDestroy() {
    eventHub.$off(FORK_UPDATED_EVENT, this.refetchLastCommit);
  },
  methods: {
    toggleShowDescription() {
      this.showDescription = !this.showDescription;
    },
    refetchLastCommit() {
      this.$apollo.queries.commit.refetch();
    },
  },
  defaultAvatarUrl,
  safeHtmlConfig: {
    ADD_TAGS: ['gl-emoji'],
  },
};
</script>

<template>
  <div class="well-segment commit gl-p-5 gl-w-full gl-display-flex">
    <gl-loading-icon v-if="isLoading" size="lg" color="dark" class="m-auto" />
    <template v-else-if="commit">
      <user-avatar-link
        v-if="commit.author"
        :link-href="commit.author.webPath"
        :img-src="commit.author.avatarUrl"
        :img-size="32"
        class="gl-my-2 gl-mr-4"
      />
      <user-avatar-image
        v-else
        class="gl-my-2 gl-mr-4"
        :img-src="commit.authorGravatar || $options.defaultAvatarUrl"
        :size="32"
      />
      <div
        class="commit-detail flex-list gl-display-flex gl-justify-content-space-between gl-align-items-flex-start gl-flex-grow-1 gl-min-w-0"
      >
        <div class="commit-content" data-qa-selector="commit_content">
          <gl-link
            v-safe-html:[$options.safeHtmlConfig]="commit.titleHtml"
            :href="commit.webPath"
            :class="{ 'font-italic': !commit.message }"
            class="commit-row-message item-title"
          />
          <gl-button
            v-if="commit.descriptionHtml"
            v-gl-tooltip
            :class="{ open: showDescription }"
            :title="__('Toggle commit description')"
            :aria-label="__('Toggle commit description')"
            :selected="showDescription"
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
            v-if="commitDescription"
            v-safe-html:[$options.safeHtmlConfig]="commitDescription"
            :class="{ 'd-block': showDescription }"
            class="commit-row-description gl-mb-3 gl-white-space-pre-line"
          ></pre>
        </div>
        <div class="gl-flex-grow-1"></div>
        <div
          class="commit-actions gl-display-flex gl-flex-align gl-align-items-center gl-flex-direction-row"
        >
          <signature-badge v-if="commit.signature" :signature="commit.signature" />
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
            <gl-button label class="gl-font-monospace" data-testid="last-commit-id-label">{{
              showCommitId
            }}</gl-button>
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
