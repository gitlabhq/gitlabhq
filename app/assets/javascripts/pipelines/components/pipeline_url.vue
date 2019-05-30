<script>
import { GlLink, GlTooltipDirective } from '@gitlab/ui';
import _ from 'underscore';
import { __, sprintf } from '~/locale';
import PipelineLink from '~/vue_shared/components/ci_pipeline_link.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import popover from '~/vue_shared/directives/popover';

const popoverTitle = sprintf(
  _.escape(
    __(
      `This pipeline makes use of a predefined CI/CD configuration enabled by %{strongStart}Auto DevOps.%{strongEnd}`,
    ),
  ),
  { strongStart: '<b>', strongEnd: '</b>' },
  false,
);

export default {
  components: {
    UserAvatarLink,
    GlLink,
    PipelineLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
            ${popoverTitle}
          </div>`,
        content: `<a
            class="autodevops-link"
            href="${this.autoDevopsHelpPath}"
            target="_blank"
            rel="noopener noreferrer nofollow">
            ${_.escape(__('Learn more about Auto DevOps'))}
          </a>`,
      };
    },
  },
};
</script>
<template>
  <div class="table-section section-10 d-none d-sm-none d-md-block pipeline-tags section-wrap">
    <pipeline-link
      :href="pipeline.path"
      :pipeline-id="pipeline.id"
      :pipeline-iid="pipeline.iid"
      class="js-pipeline-url-link"
    />
    <div class="label-container">
      <span
        v-if="pipeline.flags.latest"
        v-gl-tooltip
        :title="__('Latest pipeline for this branch')"
        class="js-pipeline-url-latest badge badge-success"
      >
        {{ __('latest') }}
      </span>
      <span
        v-if="pipeline.flags.yaml_errors"
        v-gl-tooltip
        :title="pipeline.yaml_errors"
        class="js-pipeline-url-yaml badge badge-danger"
      >
        {{ __('yaml invalid') }}
      </span>
      <span
        v-if="pipeline.flags.failure_reason"
        v-gl-tooltip
        :title="pipeline.failure_reason"
        class="js-pipeline-url-failure badge badge-danger"
      >
        {{ __('error') }}
      </span>
      <gl-link
        v-if="pipeline.flags.auto_devops"
        v-popover="popoverOptions"
        tabindex="0"
        class="js-pipeline-url-autodevops badge badge-info autodevops-badge"
        role="button"
      >
        Auto DevOps
      </gl-link>
      <span v-if="pipeline.flags.stuck" class="js-pipeline-url-stuck badge badge-warning">
        {{ __('stuck') }}
      </span>
      <span
        v-if="pipeline.flags.detached_merge_request_pipeline"
        v-gl-tooltip
        :title="__('This pipeline is run on the source branch')"
        class="js-pipeline-url-detached badge badge-info"
      >
        {{ __('detached') }}
      </span>
    </div>
  </div>
</template>
