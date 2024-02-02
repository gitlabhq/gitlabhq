import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import PasswordPromptModal from './password_prompt_modal.vue';

Vue.use(Translate);

const emailFieldSelector = '#user_email';
const editFormSelector = '.js-password-prompt-form';
const passwordPromptFieldSelector = '.js-password-prompt-field';
const passwordPromptBtnSelector = '.js-password-prompt-btn';

const passwordPromptModalId = 'password-prompt-modal';

const getEmailValue = () => document.querySelector(emailFieldSelector).value.trim();
const passwordPromptButton = document.querySelector(passwordPromptBtnSelector);
const field = document.querySelector(passwordPromptFieldSelector);
const form = document.querySelector(editFormSelector);

const handleConfirmPassword = (pw) => {
  // update the validation_password field
  field.value = pw;
  // submit the form
  form.submit();
};

export default () => {
  const passwordPromptModalEl = document.getElementById(passwordPromptModalId);

  if (passwordPromptModalEl && field) {
    return new Vue({
      el: passwordPromptModalEl,
      data() {
        return {
          initialEmail: '',
        };
      },
      mounted() {
        this.initialEmail = getEmailValue();
        passwordPromptButton.addEventListener('click', this.handleSettingsUpdate);
      },
      methods: {
        handleSettingsUpdate(ev) {
          const email = getEmailValue();
          if (email !== this.initialEmail) {
            ev.preventDefault();
            this.$root.$emit('bv::show::modal', passwordPromptModalId, passwordPromptBtnSelector);
          }
        },
      },
      render(createElement) {
        return createElement(PasswordPromptModal, {
          props: { handleConfirmPassword },
        });
      },
    });
  }
  return null;
};
