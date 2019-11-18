<script>
import { GlTooltipDirective, GlLink, GlButton, GlLoadingIcon } from '@gitlab/ui';
import defaultAvatarUrl from 'images/no_avatar.png';
import { sprintf, s__ } from '~/locale';
import Icon from '../../vue_shared/components/icon.vue';
import UserAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import TimeagoTooltip from '../../vue_shared/components/time_ago_tooltip.vue';
import CiIcon from '../../vue_shared/components/ci_icon.vue';
import ClipboardButton from '../../vue_shared/components/clipboard_button.vue';
import getRefMixin from '../mixins/get_ref';
import getProjectPath from '../queries/getProjectPath.query.graphql';
import pathLastCommit from '../queries/pathLastCommit.query.graphql';

export default {
  components: {
    Icon,
    UserAvatarLink,
    TimeagoTooltip,
    ClipboardButton,
    CiIcon,
    GlLink,
    GlButton,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [getRefMixin],
  apollo: {
    projectPath: {
      query: getProjectPath,
    },
    commit: {
      query: pathLastCommit,
      variables() {
        return {
          projectPath: this.projectPath,
          ref: this.ref,
          path: this.currentPath.replace(/^\//, ''),
        };
      },
      update: data => {
        const pipelines = data.project.repository.tree.lastCommit.pipelines.edges;

        return {
          ...data.project.repository.tree.lastCommit,
          pipeline: pipelines.length && pipelines[0].node,
        };
      },
      context: {
        isSingleRequest: true,
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
      commit: {},
      showDescription: false,
    };
  },
  computed: {
    statusTitle() {
      return sprintf(s__('Commits|Commit: %{commitText}'), {
        commitText: this.commit.pipeline.detailedStatus.text,
      });
    },
    isLoading() {
      return this.$apollo.queries.commit.loading;
    },
    showCommitId() {
      return this.commit.sha.substr(0, 8);
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
    <gl-loading-icon v-if="isLoading" size="md" class="m-auto" />
    <template v-else>
      <user-avatar-link
        v-if="commit.author"
        :link-href="commit.author.webUrl"
        :img-src="commit.author.avatarUrl"
        :img-size="40"
        class="avatar-cell"
      />
      <span v-else class="avatar-cell user-avatar-link">
        <img :src="$options.defaultAvatarUrl" width="40" height="40" class="avatar s40" />
      </span>
      <div class="commit-detail flex-list">
        <div class="commit-content qa-commit-content">
          <gl-link :href="commit.webUrl" class="commit-row-message item-title">
            {{ commit.title }}
          </gl-link>
          <gl-button
            v-if="commit.description"
            :class="{ open: showDescription }"
            :aria-label="__('Show commit description')"
            class="text-expander"
            @click="toggleShowDescription"
          >
            <icon name="ellipsis_h" :size="10" />
          </gl-button>
          <div class="committer">
            <gl-link
              v-if="commit.author"
              :href="commit.author.webUrl"
              class="commit-author-link js-user-link"
            >
              {{ commit.author.name }}
            </gl-link>
            <template v-else>
              {{ commit.authorName }}
            </template>
            {{ s__('LastCommit|authored') }}
            <timeago-tooltip :time="commit.authoredDate" tooltip-placement="bottom" />
          </div>
          <pre
            v-if="commit.description"
            :class="{ 'd-block': showDescription }"
            class="commit-row-description append-bottom-8"
          >
            {{ commit.description }}
          </pre>
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
          <div class="commit-sha-group d-flex">
            <div class="label label-monospace monospace">
              {{ showCommitId }}
            </div>
            <clipboard-button
              :text="commit.sha"
              :title="__('Copy commit SHA')"
              tooltip-placement="bottom"
            />
          </div>
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
