<script>
import { GlButton, GlFormGroup, GlModal, GlTooltipDirective } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import PasswordInput from '~/authentication/password/components/password_input.vue';
import csrf from '~/lib/utils/csrf';
import { __ } from '~/locale';

export default {
  csrf,
  i18n: {
    currentPasswordInvalidFeedback: __('Please enter your current password.'),
    deleteButton: __('Delete'),
    password: __('Current password'),
  },
  actions: {
    cancel: {
      text: __('Cancel'),
    },
  },
  components: { GlButton, GlFormGroup, GlModal, PasswordInput },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    buttonText: {
      type: String,
      required: true,
    },
    icon: {
      type: String,
      required: false,
      default: null,
    },
    message: {
      type: String,
      required: true,
    },
    method: {
      type: String,
      required: false,
      default: 'delete',
    },
    path: {
      type: String,
      required: true,
    },
    passwordRequired: {
      type: Boolean,
      required: true,
    },
    variant: {
      type: String,
      required: false,
      default: 'danger',
    },
  },
  data() {
    return {
      passwordState: null,
      modalVisible: false,
    };
  },
  computed: {
    modalId() {
      return uniqueId('delete-authenticator-');
    },
    actionPrimary() {
      return {
        text: this.buttonText,
        attributes: {
          'data-testid': '2fa-action-primary',
          variant: this.variant === 'danger' ? 'danger' : 'confirm',
        },
      };
    },
  },
  methods: {
    showModal() {
      this.modalVisible = true;
    },
    submitForm() {
      if (this.passwordRequired && this.$refs.form.current_password.value.trim() === '') {
        this.passwordState = false;

        return;
      }

      this.$refs.form.submit();
    },
  },
};
</script>

<template>
  <div class="gl-contents">
    <gl-modal
      v-model="modalVisible"
      :title="buttonText"
      size="sm"
      :modal-id="modalId"
      :action-primary="actionPrimary"
      :action-cancel="$options.actions.cancel"
      @primary.prevent="submitForm"
    >
      <p>{{ message }}</p>
      <form ref="form" :action="path" method="post">
        <gl-form-group
          v-if="passwordRequired"
          :label="$options.i18n.password"
          label-for="current-password"
          :state="passwordState"
          :invalid-feedback="$options.i18n.currentPasswordInvalidFeedback"
        >
          <password-input id="current-password" name="current_password" />
        </gl-form-group>

        <input type="hidden" name="_method" :value="method" />
        <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
      </form>
    </gl-modal>

    <gl-button
      v-if="icon"
      v-gl-tooltip
      :title="buttonText"
      :aria-label="buttonText"
      :variant="variant"
      :icon="icon"
      data-testid="2fa-action-button"
      @click="showModal"
    />
    <gl-button v-else :variant="variant" data-testid="2fa-action-button" block @click="showModal">
      {{ buttonText }}
    </gl-button>
  </div>
</template>
