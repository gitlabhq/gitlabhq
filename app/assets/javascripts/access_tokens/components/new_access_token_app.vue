<script>
import { GlAlert } from '@gitlab/ui';
import { createAlert, VARIANT_INFO } from '~/alert';
import { __, n__, sprintf } from '~/locale';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';
import InputCopyToggleVisibility from '~/vue_shared/components/input_copy_toggle_visibility/input_copy_toggle_visibility.vue';
import { EVENT_ERROR, EVENT_SUCCESS, FORM_SELECTOR } from './constants';

const convertEventDetail = (event) => convertObjectPropsToCamelCase(event.detail, { deep: true });

export default {
  EVENT_ERROR,
  EVENT_SUCCESS,
  FORM_SELECTOR,
  name: 'NewAccessTokenApp',
  components: { DomElementListener, GlAlert, InputCopyToggleVisibility },
  i18n: {
    alertInfoMessage: __('Your new %{accessTokenType} has been created.'),
    copyButtonTitle: __('Copy %{accessTokenType}'),
    description: __("Make sure you save it - you won't be able to access it again."),
    label: __('Your new %{accessTokenType}'),
  },
  tokenInputId: 'new-access-token',
  inject: ['accessTokenType'],
  data() {
    return { errors: null, alert: null, newToken: null };
  },
  computed: {
    alertInfoMessage() {
      return sprintf(this.$options.i18n.alertInfoMessage, {
        accessTokenType: this.accessTokenType,
      });
    },
    alertDangerTitle() {
      return n__(
        'The form contains the following error:',
        'The form contains the following errors:',
        this.errors?.length ?? 0,
      );
    },
    copyButtonTitle() {
      return sprintf(this.$options.i18n.copyButtonTitle, { accessTokenType: this.accessTokenType });
    },
    formInputGroupProps() {
      return {
        id: this.$options.tokenInputId,
        'data-testid': 'created-access-token-field',
        name: this.$options.tokenInputId,
      };
    },
    label() {
      return sprintf(this.$options.i18n.label, { accessTokenType: this.accessTokenType });
    },
    isNameOrScopesSet() {
      const urlParams = new URLSearchParams(window.location.search);

      return urlParams.has('name') || urlParams.has('scopes');
    },
  },
  mounted() {
    /** @type {HTMLFormElement} */
    this.form = document.querySelector(FORM_SELECTOR);

    /** @type {HTMLButtonElement} */
    this.submitButton = this.form.querySelector(
      'button[type=submit][data-testid=create-token-button]',
    );

    // If param is set, open form on page load.
    if (this.isNameOrScopesSet) {
      document.querySelectorAll('.js-token-card').forEach((el) => {
        el.querySelector('.js-add-new-token-form').style.display = 'block';
        el.querySelector('.js-toggle-button').style.display = 'none';
      });
    }
  },
  methods: {
    beforeDisplayResults() {
      this.alert?.dismiss();
      this.$refs.container.scrollIntoView(false);

      this.errors = null;
      this.newToken = null;
    },
    enableSubmitButton() {
      this.submitButton.classList.remove('disabled');
      this.submitButton.removeAttribute('disabled');
    },
    onError(event) {
      this.beforeDisplayResults();

      const [{ errors, message }] = convertEventDetail(event);
      this.errors = errors;

      if (message) {
        this.alert = createAlert({ message });
      }

      this.enableSubmitButton();
    },
    onSuccess(event) {
      this.beforeDisplayResults();

      const [{ newToken, total }] = convertEventDetail(event);
      this.newToken = newToken;

      this.alert = createAlert({ message: this.alertInfoMessage, variant: VARIANT_INFO });

      // Selectively reset all input fields except for the date picker.
      // The form token creation is not controlled by Vue.
      this.form.querySelectorAll('input[type=text]:not([id$=expires_at])').forEach((el) => {
        el.value = '';
      });

      this.form.querySelectorAll('textarea').forEach((el) => {
        el.value = '';
      });

      this.form.querySelectorAll('input[type=checkbox]').forEach((el) => {
        el.checked = false;
      });
      this.enableSubmitButton();
      document.querySelectorAll('.js-token-card').forEach((el) => {
        el.querySelector('.js-add-new-token-form').style.display = '';
        el.querySelector('.js-toggle-button').style.display = 'block';
        el.querySelector('.js-token-count').innerText = total;
      });
    },
  },
};
</script>

<template>
  <dom-element-listener
    :selector="$options.FORM_SELECTOR"
    @[$options.EVENT_ERROR]="onError"
    @[$options.EVENT_SUCCESS]="onSuccess"
  >
    <div ref="container" data-testid="access-token-section">
      <gl-alert
        v-if="newToken"
        variant="success"
        data-testid="success-message"
        class="gl-mb-5"
        @dismiss="newToken = null"
      >
        <input-copy-toggle-visibility
          :copy-button-title="copyButtonTitle"
          :label="label"
          :label-for="$options.tokenInputId"
          :value="newToken"
          :form-input-group-props="formInputGroupProps"
          readonly
          size="lg"
          class="gl-mb-0"
        >
          <template #description>
            {{ $options.i18n.description }}
          </template>
        </input-copy-toggle-visibility>
      </gl-alert>

      <template v-if="errors">
        <gl-alert
          :title="alertDangerTitle"
          variant="danger"
          data-testid="error-message"
          @dismiss="errors = null"
        >
          <ul class="gl-m-0">
            <li v-for="error in errors" :key="error">
              {{ error }}
            </li>
          </ul>
        </gl-alert>
        <hr />
      </template>
    </div>
  </dom-element-listener>
</template>
