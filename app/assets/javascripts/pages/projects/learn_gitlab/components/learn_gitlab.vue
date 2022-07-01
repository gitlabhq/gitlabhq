<script>
import { GlProgressBar, GlSprintf, GlAlert } from '@gitlab/ui';
import eventHub from '~/invite_members/event_hub';
import { s__ } from '~/locale';
import { getCookie, removeCookie, parseBoolean } from '~/lib/utils/common_utils';
import { ACTION_LABELS, ACTION_SECTIONS, INVITE_MODAL_OPEN_COOKIE } from '../constants';
import LearnGitlabSectionCard from './learn_gitlab_section_card.vue';

export default {
  components: { GlProgressBar, GlSprintf, GlAlert, LearnGitlabSectionCard },
  i18n: {
    title: s__('LearnGitLab|Learn GitLab'),
    description: s__(
      'LearnGitLab|Ready to get started with GitLab? Follow these steps to set up your workspace, plan and commit changes, and deploy your project.',
    ),
    percentageCompleted: s__(`LearnGitLab|%{percentage}%{percentSymbol} completed`),
    successfulInvitations: s__(
      "LearnGitLab|Your team is growing! You've successfully invited new team members to the %{projectName} project.",
    ),
  },
  props: {
    actions: {
      required: true,
      type: Object,
    },
    sections: {
      required: true,
      type: Object,
    },
    project: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      showSuccessfulInvitationsAlert: false,
      actionsData: this.actions,
    };
  },
  actionSections: Object.keys(ACTION_SECTIONS),
  computed: {
    maxValue() {
      return Object.keys(this.actionsData).length;
    },
    progressValue() {
      return Object.values(this.actionsData).filter((a) => a.completed).length;
    },
    progressPercentage() {
      return Math.round((this.progressValue / this.maxValue) * 100);
    },
  },
  mounted() {
    if (this.getCookieForInviteMembers()) {
      this.openInviteMembersModal('celebrate');
    }

    eventHub.$on('showSuccessfulInvitationsAlert', this.handleShowSuccessfulInvitationsAlert);
  },
  beforeDestroy() {
    eventHub.$off('showSuccessfulInvitationsAlert', this.handleShowSuccessfulInvitationsAlert);
  },
  methods: {
    getCookieForInviteMembers() {
      const value = parseBoolean(getCookie(INVITE_MODAL_OPEN_COOKIE));

      removeCookie(INVITE_MODAL_OPEN_COOKIE);

      return value;
    },
    openInviteMembersModal(mode) {
      eventHub.$emit('openModal', { mode, source: 'learn-gitlab' });
    },
    handleShowSuccessfulInvitationsAlert() {
      this.showSuccessfulInvitationsAlert = true;
      this.markActionAsCompleted('userAdded');
    },
    actionsFor(section) {
      const actions = Object.fromEntries(
        Object.entries(this.actionsData).filter(
          ([action]) => ACTION_LABELS[action].section === section,
        ),
      );
      return actions;
    },
    svgFor(section) {
      return this.sections[section].svg;
    },
    markActionAsCompleted(completedAction) {
      Object.keys(this.actionsData).forEach((action) => {
        if (action === completedAction) {
          this.actionsData[action].completed = true;
          this.modifySidebarPercentage();
        }
      });
    },
    modifySidebarPercentage() {
      const el = document.querySelector('.sidebar-top-level-items .active .count');
      el.textContent = `${this.progressPercentage}%`;
    },
  },
};
</script>
<template>
  <div>
    <gl-alert
      v-if="showSuccessfulInvitationsAlert"
      class="gl-mt-5"
      @dismiss="showSuccessfulInvitationsAlert = false"
    >
      <gl-sprintf :message="$options.i18n.successfulInvitations">
        <template #projectName>
          <strong>{{ project.name }}</strong>
        </template>
      </gl-sprintf>
    </gl-alert>
    <div class="row">
      <div class="gl-mb-7 gl-ml-5">
        <h1 class="gl-font-size-h1">{{ $options.i18n.title }}</h1>
        <p class="gl-text-gray-700 gl-mb-0">{{ $options.i18n.description }}</p>
      </div>
    </div>
    <div class="gl-mb-3">
      <p class="gl-text-gray-500 gl-mb-2" data-testid="completion-percentage">
        <gl-sprintf :message="$options.i18n.percentageCompleted">
          <template #percentage>{{ progressPercentage }}</template>
          <template #percentSymbol>%</template>
        </gl-sprintf>
      </p>
      <gl-progress-bar :value="progressValue" :max="maxValue" />
    </div>
    <div class="row">
      <div
        v-for="section in $options.actionSections"
        :key="section"
        class="gl-mt-5 col-sm-12 col-mb-6 col-lg-4"
      >
        <learn-gitlab-section-card
          :section="section"
          :svg="svgFor(section)"
          :actions="actionsFor(section)"
        />
      </div>
    </div>
  </div>
</template>
