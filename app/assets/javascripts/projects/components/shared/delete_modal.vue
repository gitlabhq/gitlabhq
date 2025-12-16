<script>
import { GlAlert, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';
import GroupsProjectsDeleteModal from '~/groups_projects/components/delete_modal.vue';
import { RESOURCE_TYPES } from '~/groups_projects/constants';

export default {
  RESOURCE_TYPES,
  i18n: {
    isForkAlertTitle: __('You are about to delete this forked project containing:'),
    isNotForkAlertTitle: __('You are about to delete this project containing:'),
    isForkAlertBody: __('This process deletes the project repository and all related resources.'),
    isNotForkAlertBody: __(
      'This project is %{strongStart}NOT%{strongEnd} a fork. This process deletes the project repository and all related resources.',
    ),
    isNotForkMessage: __(
      'This project is %{strongStart}NOT%{strongEnd} a fork, and has the following:',
    ),
  },
  components: { GroupsProjectsDeleteModal, GlAlert, GlSprintf, HelpPageLink },
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
    confirmPhrase: {
      type: String,
      required: true,
    },
    nameWithNamespace: {
      type: String,
      required: true,
    },
    isFork: {
      type: Boolean,
      required: true,
    },
    confirmLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    issuesCount: {
      type: Number,
      required: false,
      default: null,
    },
    mergeRequestsCount: {
      type: Number,
      required: false,
      default: null,
    },
    forksCount: {
      type: Number,
      required: false,
      default: null,
    },
    starsCount: {
      type: Number,
      required: false,
      default: null,
    },
    markedForDeletion: {
      type: Boolean,
      required: true,
    },
    permanentDeletionDate: {
      type: String,
      required: true,
    },
  },
  computed: {
    hasStats() {
      return (
        this.issuesCount !== null ||
        this.mergeRequestsCount !== null ||
        this.forksCount !== null ||
        this.starsCount !== null
      );
    },
  },
  methods: {
    numberToMetricPrefix,
  },
};
</script>

<template>
  <groups-projects-delete-modal
    :resource-type="$options.RESOURCE_TYPES.PROJECT"
    :visible="visible"
    :confirm-phrase="confirmPhrase"
    :full-name="nameWithNamespace"
    :confirm-loading="confirmLoading"
    :marked-for-deletion="markedForDeletion"
    :permanent-deletion-date="permanentDeletionDate"
    @primary="$emit('primary')"
    @change="$emit('change', $event)"
  >
    <template #alert>
      <gl-alert class="gl-mb-5" variant="danger" :dismissible="false">
        <h4 v-if="isFork" class="gl-alert-title">
          {{ $options.i18n.isForkAlertTitle }}
        </h4>
        <h4 v-else class="gl-alert-title">
          {{ $options.i18n.isNotForkAlertTitle }}
        </h4>
        <ul v-if="hasStats" data-testid="project-delete-modal-stats">
          <li v-if="issuesCount !== null">
            <gl-sprintf :message="n__('%{count} issue', '%{count} issues', issuesCount)">
              <template #count>{{ numberToMetricPrefix(issuesCount) }}</template>
            </gl-sprintf>
          </li>
          <li v-if="mergeRequestsCount !== null">
            <gl-sprintf
              :message="
                n__('%{count} merge request', '%{count} merge requests', mergeRequestsCount)
              "
            >
              <template #count>{{ numberToMetricPrefix(mergeRequestsCount) }}</template>
            </gl-sprintf>
          </li>
          <li v-if="forksCount !== null">
            <gl-sprintf :message="n__('%{count} fork', '%{count} forks', forksCount)">
              <template #count>{{ numberToMetricPrefix(forksCount) }}</template>
            </gl-sprintf>
          </li>
          <li v-if="starsCount !== null">
            <gl-sprintf :message="n__('%{count} star', '%{count} stars', starsCount)">
              <template #count>{{ numberToMetricPrefix(starsCount) }}</template>
            </gl-sprintf>
          </li>
        </ul>
        <gl-sprintf v-if="isFork" :message="$options.i18n.isForkAlertBody" />
        <gl-sprintf v-else :message="$options.i18n.isNotForkAlertBody">
          <template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </gl-alert>
    </template>
    <template #restore-help-page-link="{ content }">
      <help-page-link href="user/project/working_with_projects" anchor="restore-a-project">{{
        content
      }}</help-page-link>
    </template>
  </groups-projects-delete-modal>
</template>
