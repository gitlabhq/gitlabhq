<script>
import { uniqueId } from 'lodash';
import { GlLink, GlIcon, GlButton, GlPopover, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import { isExperimentVariant } from '~/experimentation/utils';
import eventHub from '~/invite_members/event_hub';
import { s__, __ } from '~/locale';
import { ACTION_LABELS } from '../constants';

export default {
  name: 'LearnGitlabSectionLink',
  components: {
    GlLink,
    GlIcon,
    GlButton,
    GlPopover,
    GitlabExperiment,
  },
  directives: {
    GlTooltip,
  },
  i18n: {
    trialOnly: s__('LearnGitlab|Trial only'),
    contactAdmin: s__('LearnGitlab|Contact your administrator to start a free Ultimate trial.'),
    viewAdminList: s__('LearnGitlab|View administrator list'),
    watchHow: __('Watch how'),
  },
  props: {
    action: {
      required: true,
      type: String,
    },
    value: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      popoverId: uniqueId('contact-admin-'),
    };
  },
  computed: {
    linkTitle() {
      return ACTION_LABELS[this.action].title;
    },
    trialOnly() {
      return ACTION_LABELS[this.action].trialRequired;
    },
    showInviteModalLink() {
      return (
        this.action === 'userAdded' && isExperimentVariant('invite_for_help_continuous_onboarding')
      );
    },
    openInNewTab() {
      return ACTION_LABELS[this.action]?.openInNewTab === true || this.value.openInNewTab === true;
    },
    linkToVideoTutorial() {
      return ACTION_LABELS[this.action].videoTutorial;
    },
  },
  methods: {
    openModal() {
      eventHub.$emit('openModal', { source: 'learn_gitlab' });
    },
  },
};
</script>
<template>
  <div class="gl-mb-4">
    <div v-if="trialOnly" class="gl-font-style-italic gl-text-gray-500" data-testid="trial-only">
      {{ $options.i18n.trialOnly }}
    </div>
    <div class="flex align-items-center">
      <span v-if="value.completed" class="gl-text-green-500">
        <gl-icon name="check-circle-filled" :size="16" data-testid="completed-icon" />
        {{ linkTitle }}
      </span>
      <gl-link
        v-else-if="showInviteModalLink"
        data-track-action="click_link"
        :data-track-label="linkTitle"
        data-track-property="Growth::Activation::Experiment::InviteForHelpContinuousOnboarding"
        data-testid="invite-for-help-continuous-onboarding-experiment-link"
        @click="openModal"
      >
        {{ linkTitle }}
      </gl-link>
      <gl-link
        v-else-if="value.enabled"
        :target="openInNewTab ? '_blank' : '_self'"
        :href="value.url"
        data-testid="uncompleted-learn-gitlab-link"
        data-track-action="click_link"
        :data-track-label="linkTitle"
      >
        {{ linkTitle }}
      </gl-link>
      <template v-else>
        <div data-testid="disabled-learn-gitlab-link">{{ linkTitle }}</div>
        <gl-button
          :id="popoverId"
          category="tertiary"
          icon="question-o"
          class="ml-auto"
          :aria-label="$options.i18n.contactAdmin"
          size="small"
          data-testid="contact-admin-popover-trigger"
        />
        <gl-popover
          :target="popoverId"
          placement="top"
          triggers="hover focus"
          data-testid="contact-admin-popover"
        >
          <p>{{ $options.i18n.contactAdmin }}</p>
          <gl-link
            :href="value.url"
            class="font-size-inherit"
            data-testid="view-administrator-link-text"
          >
            {{ $options.i18n.viewAdminList }}
          </gl-link>
        </gl-popover>
      </template>
      <gitlab-experiment name="video_tutorials_continuous_onboarding">
        <template #control></template>
        <template #candidate>
          <gl-button
            v-if="linkToVideoTutorial"
            v-gl-tooltip
            category="tertiary"
            icon="live-preview"
            :title="$options.i18n.watchHow"
            :aria-label="$options.i18n.watchHow"
            :href="linkToVideoTutorial"
            target="_blank"
            class="ml-auto"
            size="small"
            data-testid="video-tutorial-link"
            data-track-action="click_video_link"
            :data-track-label="linkTitle"
            data-track-property="Growth::Conversion::Experiment::LearnGitLab"
            data-track-experiment="video_tutorials_continuous_onboarding"
          />
        </template>
      </gitlab-experiment>
    </div>
  </div>
</template>
