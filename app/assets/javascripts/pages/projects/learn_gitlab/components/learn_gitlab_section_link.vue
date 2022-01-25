<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import { isExperimentVariant } from '~/experimentation/utils';
import eventHub from '~/invite_members/event_hub';
import { s__ } from '~/locale';
import { ACTION_LABELS } from '../constants';

export default {
  name: 'LearnGitlabSectionLink',
  components: { GlLink, GlIcon },
  i18n: {
    ACTION_LABELS,
    trialOnly: s__('LearnGitlab|Trial only'),
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
  computed: {
    trialOnly() {
      return ACTION_LABELS[this.action].trialRequired;
    },
    showInviteModalLink() {
      return (
        this.action === 'userAdded' && isExperimentVariant('invite_for_help_continuous_onboarding')
      );
    },
    openInNewTab() {
      return ACTION_LABELS[this.action]?.openInNewTab === true;
    },
  },
  methods: {
    openModal() {
      eventHub.$emit('openModal', {
        inviteeType: 'members',
        source: 'learn_gitlab',
        tasksToBeDoneEnabled: true,
      });
    },
  },
};
</script>
<template>
  <div class="gl-mb-4">
    <span v-if="value.completed" class="gl-text-green-500">
      <gl-icon name="check-circle-filled" :size="16" data-testid="completed-icon" />
      {{ $options.i18n.ACTION_LABELS[action].title }}
    </span>
    <gl-link
      v-else-if="showInviteModalLink"
      data-track-action="click_link"
      :data-track-label="$options.i18n.ACTION_LABELS[action].title"
      data-track-property="Growth::Activation::Experiment::InviteForHelpContinuousOnboarding"
      data-testid="invite-for-help-continuous-onboarding-experiment-link"
      @click="openModal"
    >
      {{ $options.i18n.ACTION_LABELS[action].title }}
    </gl-link>
    <gl-link
      v-else
      :target="openInNewTab ? '_blank' : '_self'"
      :href="value.url"
      data-testid="uncompleted-learn-gitlab-link"
      data-track-action="click_link"
      :data-track-label="$options.i18n.ACTION_LABELS[action].title"
      data-track-property="Growth::Conversion::Experiment::LearnGitLab"
      data-track-experiment="change_continuous_onboarding_link_urls"
    >
      {{ $options.i18n.ACTION_LABELS[action].title }}
    </gl-link>
    <span v-if="trialOnly" class="gl-font-style-italic gl-text-gray-500" data-testid="trial-only">
      - {{ $options.i18n.trialOnly }}
    </span>
  </div>
</template>
