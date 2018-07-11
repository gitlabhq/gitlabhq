<script>
import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import tooltip from '../../vue_shared/directives/tooltip';
import popover from '../../vue_shared/directives/popover';

export default {
  components: {
    userAvatarLink,
  },
  directives: {
    tooltip,
    popover,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
    autoDevopsHelpPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    user() {
      return this.pipeline.user;
    },
    popoverOptions() {
      return {
        html: true,
        trigger: 'focus',
        placement: 'top',
        title: `<div class="autodevops-title">
            This pipeline makes use of a predefined CI/CD configuration enabled by <b>Auto DevOps.</b>
          </div>`,
        content: `<a
            class="autodevops-link"
            href="${this.autoDevopsHelpPath}"
            target="_blank"
            rel="noopener noreferrer nofollow">
            Learn more about Auto DevOps
          </a>`,
      };
    },
  },
};
</script>
<template>
  <div class="table-section section-15 d-none d-sm-none d-md-block pipeline-tags">
    <a
      :href="pipeline.path"
      class="js-pipeline-url-link">
      <span class="pipeline-id">#{{ pipeline.id }}</span>
    </a>
    <span>by</span>
    <user-avatar-link
      v-if="user"
      :link-href="pipeline.user.path"
      :img-src="pipeline.user.avatar_url"
      :tooltip-text="pipeline.user.name"
      class="js-pipeline-url-user"
    />
    <span
      v-if="!user"
      class="js-pipeline-url-api api">
      API
    </span>
    <div class="label-container">
      <span
        v-tooltip
        v-if="pipeline.flags.latest"
        class="js-pipeline-url-latest badge badge-success"
        title="Latest pipeline for this branch">
        latest
      </span>
      <span
        v-tooltip
        v-if="pipeline.flags.yaml_errors"
        :title="pipeline.yaml_errors"
        class="js-pipeline-url-yaml badge badge-danger">
        yaml invalid
      </span>
      <span
        v-tooltip
        v-if="pipeline.flags.failure_reason"
        :title="pipeline.failure_reason"
        class="js-pipeline-url-failure badge badge-danger">
        error
      </span>
      <a
        v-popover="popoverOptions"
        v-if="pipeline.flags.auto_devops"
        tabindex="0"
        class="js-pipeline-url-autodevops badge badge-info autodevops-badge"
        role="button">
        Auto DevOps
      </a>
      <span
        v-if="pipeline.flags.stuck"
        class="js-pipeline-url-stuck badge badge-warning">
        stuck
      </span>
    </div>
  </div>
</template>
