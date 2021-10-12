<script>
import {
  GlButton,
  GlFormGroup,
  GlFormInput,
  GlModal,
  GlModalDirective,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  copyToClipboard: __('Copy'),
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlModal,
    ClipboardButton,
    GlSprintf,
    GlLink,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  props: {
    initialAuthorizationKey: {
      type: String,
      required: false,
      default: '',
    },
    changeKeyUrl: {
      type: String,
      required: true,
    },
    notifyUrl: {
      type: String,
      required: true,
    },
    learnMoreUrl: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      authorizationKey: this.initialAuthorizationKey,
    };
  },
  methods: {
    resetKey() {
      axios
        .post(this.changeKeyUrl)
        .then((res) => {
          this.authorizationKey = res.data.token;
        })
        .catch(() => {
          createFlash({
            message: __('Failed to reset key. Please try again.'),
          });
        });
    },
  },
};
</script>

<template>
  <div class="row py-4 border-top js-prometheus-alerts">
    <div class="col-lg-3">
      <h4 class="mt-0">
        {{ __('Alerts') }}
      </h4>
      <p>
        {{ __('Receive alerts from manually configured Prometheus servers.') }}
      </p>
    </div>
    <div class="col-lg-9">
      <gl-sprintf
        :message="
          __(
            'To receive alerts from manually configured Prometheus services, add the following URL and Authorization key to your Prometheus webhook config file. Learn more about %{linkStart}configuring Prometheus%{linkEnd} to send alerts to GitLab.',
          )
        "
      >
        <template #link="{ content }">
          <gl-link :href="learnMoreUrl" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
      <gl-form-group :label="__('URL')" label-for="notify-url" label-class="label-bold">
        <div class="input-group">
          <gl-form-input id="notify-url" :readonly="true" :value="notifyUrl" />
          <span class="input-group-append">
            <clipboard-button
              :text="notifyUrl"
              :title="$options.copyToClipboard"
              :disabled="disabled"
            />
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
            <clipboard-button
              :text="authorizationKey"
              :title="$options.copyToClipboard"
              :disabled="disabled"
            />
          </span>
        </div>
      </gl-form-group>
      <template v-if="authorizationKey.length > 0">
        <gl-modal
          modal-id="authKeyModal"
          :title="__('Reset authorization key?')"
          :ok-title="__('Reset authorization key')"
          ok-variant="danger"
          @ok="resetKey"
        >
          {{
            __(
              'Resetting the authorization key will invalidate the previous key. Existing alert configurations will need to be updated with the new key.',
            )
          }}
        </gl-modal>
        <gl-button v-gl-modal.authKeyModal class="js-reset-auth-key" :disabled="disabled">{{
          __('Reset key')
        }}</gl-button>
      </template>
      <gl-button v-else :disabled="disabled" class="js-reset-auth-key" @click="resetKey">{{
        __('Generate key')
      }}</gl-button>
    </div>
  </div>
</template>
