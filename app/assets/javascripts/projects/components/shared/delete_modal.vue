<script>
import { GlModal, GlAlert, GlSprintf, GlFormInput } from '@gitlab/ui';
import uniqueId from 'lodash/uniqueId';
import { __, s__, sprintf } from '~/locale';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import { numberToMetricPrefix } from '~/lib/utils/number_utils';

export default {
  i18n: {
    deleteProject: __('Delete project'),
    title: __('Are you absolutely sure?'),
    confirmText: __('Enter the following to confirm:'),
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
  components: { GlModal, GlAlert, GlSprintf, GlFormInput, HelpPageLink },
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
  data() {
    return {
      userInput: null,
      modalId: uniqueId('delete-project-modal-'),
    };
  },
  computed: {
    confirmDisabled() {
      return this.userInput !== this.confirmPhrase;
    },
    modalActionProps() {
      return {
        primary: {
          text: __('Yes, delete project'),
          attributes: {
            variant: 'danger',
            disabled: this.confirmDisabled,
            loading: this.confirmLoading,
            'data-testid': 'confirm-delete-button',
          },
        },
        cancel: {
          text: __('Cancel, keep project'),
        },
      };
    },
    ariaLabel() {
      return sprintf(s__('Projects|Delete %{nameWithNamespace}'), {
        nameWithNamespace: this.nameWithNamespace,
      });
    },
    showRestoreMessage() {
      return !this.markedForDeletion;
    },
    hasStats() {
      return (
        this.issuesCount !== null ||
        this.mergeRequestsCount !== null ||
        this.forksCount !== null ||
        this.starsCount !== null
      );
    },
  },
  watch: {
    confirmLoading(isLoading, wasLoading) {
      // If the button was loading and now no longer is
      if (!isLoading && wasLoading) {
        // Hide the modal
        this.$emit('change', false);
      }
    },
  },
  methods: {
    numberToMetricPrefix,
  },
};
</script>

<template>
  <gl-modal
    :visible="visible"
    :modal-id="modalId"
    footer-class="gl-bg-subtle gl-p-5"
    title-class="gl-text-danger"
    :action-primary="modalActionProps.primary"
    :action-cancel="modalActionProps.cancel"
    :aria-label="ariaLabel"
    @primary.prevent="$emit('primary')"
    @change="$emit('change', $event)"
  >
    <template #modal-title>{{ $options.i18n.title }}</template>
    <div>
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
      <p class="gl-mb-1">{{ $options.i18n.confirmText }}</p>
      <p>
        <code class="gl-whitespace-pre-wrap">{{ confirmPhrase }}</code>
      </p>

      <gl-form-input
        id="confirm_name_input"
        v-model="userInput"
        name="confirm_name_input"
        type="text"
        data-testid="confirm-name-field"
      />
      <p
        v-if="showRestoreMessage"
        class="gl-mb-0 gl-mt-3 gl-text-subtle"
        data-testid="restore-message"
      >
        <gl-sprintf
          :message="
            __('This project can be restored until %{date}. %{linkStart}Learn more%{linkEnd}.')
          "
        >
          <template #date>{{ permanentDeletionDate }}</template>
          <template #link="{ content }">
            <help-page-link href="user/project/working_with_projects" anchor="restore-a-project">{{
              content
            }}</help-page-link>
          </template>
        </gl-sprintf>
      </p>
    </div>
  </gl-modal>
</template>
