<script>
import { GlModal, GlModalDirective, GlSprintf, GlFormInput, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import { rstrip } from '~/lib/utils/common_utils';
import csrf from '~/lib/utils/csrf';

export default {
  components: {
    GlModal,
    GlSprintf,
    GlFormInput,
    GlButton,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    confirmPhrase: {
      type: String,
      required: true,
    },
    warningMessage: {
      type: String,
      required: true,
    },
    formPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      userInput: null,
    };
  },
  computed: {
    buttonDisabled() {
      return rstrip(this.userInput) !== this.confirmPhrase;
    },
    csrfToken() {
      return csrf.token;
    },
  },
  methods: {
    submitForm() {
      this.$refs.form.submit();
    },
  },
  strings: {
    removeProject: __('Remove project'),
    title: __('Confirmation required'),
    confirm: __('Confirm'),
    dataLoss: __(
      'This action can lead to data loss. To prevent accidental actions we ask you to confirm your intention.',
    ),
    confirmText: __('Please type %{phrase_code} to proceed or close this modal to cancel.'),
  },
  modalId: 'remove-project-modal',
};
</script>

<template>
  <form ref="form" :action="formPath" method="post">
    <input type="hidden" name="_method" value="delete" />
    <input :value="csrfToken" type="hidden" name="authenticity_token" />
    <gl-button v-gl-modal="$options.modalId" category="primary" variant="danger">{{
      $options.strings.removeProject
    }}</gl-button>
    <gl-modal
      ref="removeModal"
      :modal-id="$options.modalId"
      size="sm"
      ok-variant="danger"
      footer-class="bg-gray-light gl-p-5"
    >
      <template #modal-title>{{ $options.strings.title }}</template>
      <template #modal-footer>
        <div class="gl-w-full gl-display-flex gl-just-content-start gl-m-0">
          <gl-button
            :disabled="buttonDisabled"
            category="primary"
            variant="danger"
            @click="submitForm"
          >
            {{ $options.strings.confirm }}
          </gl-button>
        </div>
      </template>
      <div>
        <p class="gl-text-red-500 gl-font-weight-bold">{{ warningMessage }}</p>
        <p class="gl-mb-0">{{ $options.strings.dataLoss }}</p>
        <p>
          <gl-sprintf :message="$options.strings.confirmText">
            <template #phrase_code>
              <code>{{ confirmPhrase }}</code>
            </template>
          </gl-sprintf>
        </p>
        <gl-form-input
          id="confirm_name_input"
          v-model="userInput"
          name="confirm_name_input"
          type="text"
        />
      </div>
    </gl-modal>
  </form>
</template>
