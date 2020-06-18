<script>
import {
  GlButton,
  GlFormGroup,
  GlFormInput,
  GlLink,
  GlModal,
  GlModalDirective,
  GlSprintf,
} from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ToggleButton from '~/vue_shared/components/toggle_button.vue';
import axios from '~/lib/utils/axios_utils';
import { s__, __ } from '~/locale';
import createFlash from '~/flash';

export default {
  i18n: {
    usageSection: s__(
      'AlertService|You must provide this URL and authorization key to authorize an external service to send alerts to GitLab. You can provide this URL and key to multiple services. After configuring an external service, alerts from your service will display on the GitLab %{linkStart}Alerts%{linkEnd} page.',
    ),
    setupSection: s__(
      "AlertService|Review your external service's documentation to learn where to provide this information to your external service, and the %{linkStart}GitLab documentation%{linkEnd} to learn more about configuring your endpoint.",
    ),
  },
  COPY_TO_CLIPBOARD: __('Copy'),
  RESET_KEY: __('Reset key'),
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlLink,
    GlModal,
    GlSprintf,
    ClipboardButton,
    ToggleButton,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  props: {
    alertsSetupUrl: {
      type: String,
      required: true,
    },
    alertsUsageUrl: {
      type: String,
      required: true,
    },
    initialAuthorizationKey: {
      type: String,
      required: false,
      default: '',
    },
    formPath: {
      type: String,
      required: true,
    },
    url: {
      type: String,
      required: true,
    },
    initialActivated: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      activated: this.initialActivated,
      loadingActivated: false,
      authorizationKey: this.initialAuthorizationKey,
    };
  },
  computed: {
    sections() {
      return [
        {
          text: this.$options.i18n.usageSection,
          url: this.alertsUsageUrl,
        },
        {
          text: this.$options.i18n.setupSection,
          url: this.alertsSetupUrl,
        },
      ];
    },
  },
  watch: {
    activated() {
      this.updateIcon();
    },
  },
  methods: {
    updateIcon() {
      return document.querySelectorAll('.js-service-active-status').forEach(icon => {
        if (icon.dataset.value === this.activated.toString()) {
          icon.classList.remove('d-none');
        } else {
          icon.classList.add('d-none');
        }
      });
    },
    resetKey() {
      return axios
        .put(this.formPath, { service: { token: '' } })
        .then(res => {
          this.authorizationKey = res.data.token;
        })
        .catch(() => {
          createFlash(__('Failed to reset key. Please try again.'));
        });
    },
    toggleActivated(value) {
      this.loadingActivated = true;
      return axios
        .put(this.formPath, { service: { active: value } })
        .then(() => {
          this.activated = value;
          this.loadingActivated = false;
        })
        .catch(() => {
          createFlash(__('Update failed. Please try again.'));
          this.loadingActivated = false;
        });
    },
  },
};
</script>

<template>
  <div>
    <div data-testid="description">
      <p v-for="section in sections" :key="section.text">
        <gl-sprintf :message="section.text">
          <template #link="{ content }">
            <gl-link :href="section.url" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </div>
    <gl-form-group :label="__('Active')" label-for="activated" label-class="label-bold">
      <toggle-button
        id="activated"
        :disabled-input="loadingActivated"
        :is-loading="loadingActivated"
        :value="activated"
        @change="toggleActivated"
      />
    </gl-form-group>
    <gl-form-group :label="__('URL')" label-for="url" label-class="label-bold">
      <div class="input-group">
        <gl-form-input id="url" :readonly="true" :value="url" />
        <span class="input-group-append">
          <clipboard-button :text="url" :title="$options.COPY_TO_CLIPBOARD" />
        </span>
      </div>
    </gl-form-group>
    <gl-form-group
      :label="__('Authorization key')"
      label-for="authorization-key"
      label-class="label-bold"
    >
      <div class="input-group">
        <gl-form-input id="authorization-key" :readonly="true" :value="authorizationKey" />
        <span class="input-group-append">
          <clipboard-button :text="authorizationKey" :title="$options.COPY_TO_CLIPBOARD" />
        </span>
      </div>
      <gl-button v-gl-modal.authKeyModal class="mt-2">{{ $options.RESET_KEY }}</gl-button>
      <gl-modal
        modal-id="authKeyModal"
        :title="$options.RESET_KEY"
        :ok-title="$options.RESET_KEY"
        ok-variant="danger"
        @ok="resetKey"
      >
        {{
          __(
            'Resetting the authorization key for this project will require updating the authorization key in every alert source it is enabled in.',
          )
        }}
      </gl-modal>
    </gl-form-group>
  </div>
</template>
