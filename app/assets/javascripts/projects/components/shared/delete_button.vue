<script>
import { GlModal, GlModalDirective, GlFormInput, GlButton, GlAlert, GlSprintf } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import csrf from '~/lib/utils/csrf';
import { __ } from '~/locale';

export default {
  components: {
    GlAlert,
    GlModal,
    GlFormInput,
    GlButton,
    GlSprintf,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    confirmPhrase: {
      type: String,
      required: true,
    },
    formPath: {
      type: String,
      required: true,
    },
    isFork: {
      type: Boolean,
      required: true,
    },
    issuesCount: {
      type: Number,
      required: true,
    },
    mergeRequestsCount: {
      type: Number,
      required: true,
    },
    forksCount: {
      type: Number,
      required: true,
    },
    starsCount: {
      type: Number,
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
    csrfToken() {
      return csrf.token;
    },
    modalActionProps() {
      return {
        primary: {
          text: __('Yes, delete project'),
          attributes: {
            variant: 'danger',
            disabled: this.confirmDisabled,
            'data-qa-selector': 'confirm_delete_button',
          },
        },
        cancel: {
          text: __('Cancel, keep project'),
        },
      };
    },
  },
  methods: {
    submitForm() {
      this.$refs.form.submit();
    },
  },
  strings: {
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
};
</script>

<template>
  <form ref="form" :action="formPath" method="post">
    <input type="hidden" name="_method" value="delete" />
    <input :value="csrfToken" type="hidden" name="authenticity_token" />

    <gl-button
      v-gl-modal="modalId"
      category="primary"
      variant="danger"
      data-qa-selector="delete_button"
      >{{ $options.strings.deleteProject }}</gl-button
    >

    <gl-modal
      ref="removeModal"
      :modal-id="modalId"
      ok-variant="danger"
      footer-class="gl-bg-gray-10 gl-p-5"
      title-class="gl-text-red-500"
      :action-primary="modalActionProps.primary"
      :action-cancel="modalActionProps.cancel"
      @ok="submitForm"
    >
      <template #modal-title>{{ $options.strings.title }}</template>
      <div>
        <gl-alert class="gl-mb-5" variant="danger" :dismissible="false">
          <h4 v-if="isFork" data-testid="delete-alert-title" class="gl-alert-title">
            {{ $options.strings.isForkAlertTitle }}
          </h4>
          <h4 v-else data-testid="delete-alert-title" class="gl-alert-title">
            {{ $options.strings.isNotForkAlertTitle }}
          </h4>
          <ul>
            <li>
              <gl-sprintf :message="n__('%d issue', '%d issues', issuesCount)">
                <template #issuesCount>{{ issuesCount }}</template>
              </gl-sprintf>
            </li>
            <li>
              <gl-sprintf
                :message="n__('%d merge requests', '%d merge requests', mergeRequestsCount)"
              >
                <template #mergeRequestsCount>{{ mergeRequestsCount }}</template>
              </gl-sprintf>
            </li>
            <li>
              <gl-sprintf :message="n__('%d fork', '%d forks', forksCount)">
                <template #forksCount>{{ forksCount }}</template>
              </gl-sprintf>
            </li>
            <li>
              <gl-sprintf :message="n__('%d star', '%d stars', starsCount)">
                <template #starsCount>{{ starsCount }}</template>
              </gl-sprintf>
            </li>
          </ul>
          <gl-sprintf
            v-if="isFork"
            data-testid="delete-alert-body"
            :message="$options.strings.isForkAlertBody"
          />
          <gl-sprintf
            v-else
            data-testid="delete-alert-body"
            :message="$options.strings.isNotForkAlertBody"
          >
            <template #strong="{ content }">
              <strong>{{ content }}</strong>
            </template>
          </gl-sprintf>
        </gl-alert>
        <p class="gl-mb-1">{{ $options.strings.confirmText }}</p>
        <p>
          <code class="gl-white-space-pre-wrap">{{ confirmPhrase }}</code>
        </p>
        <gl-form-input
          id="confirm_name_input"
          v-model="userInput"
          name="confirm_name_input"
          type="text"
          data-qa-selector="confirm_name_field"
        />
        <slot name="modal-footer"></slot>
      </div>
    </gl-modal>
  </form>
</template>
