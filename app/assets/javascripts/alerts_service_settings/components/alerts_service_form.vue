<script>
import {
  GlDeprecatedButton,
  GlFormGroup,
  GlFormInput,
  GlModal,
  GlModalDirective,
} from '@gitlab/ui';
import { escape as esc } from 'lodash';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ToggleButton from '~/vue_shared/components/toggle_button.vue';
import axios from '~/lib/utils/axios_utils';
import { s__, __, sprintf } from '~/locale';
import createFlash from '~/flash';

export default {
  COPY_TO_CLIPBOARD: __('Copy'),
  RESET_KEY: __('Reset key'),
  components: {
    GlDeprecatedButton,
    GlFormGroup,
    GlFormInput,
    GlModal,
    ClipboardButton,
    ToggleButton,
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
    formPath: {
      type: String,
      required: true,
    },
    url: {
      type: String,
      required: true,
    },
    learnMoreUrl: {
      type: String,
      required: false,
      default: '',
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
    learnMoreDescription() {
      return sprintf(
        s__(
          'AlertService|%{linkStart}Learn more%{linkEnd} about configuring this endpoint to receive alerts.',
        ),
        {
          linkStart: `<a href="${esc(
            this.learnMoreUrl,
          )}" target="_blank" rel="noopener noreferrer">`,
          linkEnd: '</a>',
        },
        false,
      );
    },
    sectionDescription() {
      const desc = s__(
        'AlertService|Each alert source must be authorized using the following URL and authorization key.',
      );
      const learnMoreDesc = this.learnMoreDescription ? ` ${this.learnMoreDescription}` : '';

      return `${desc}${learnMoreDesc}`;
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
    <p v-html="sectionDescription"></p>
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
      <gl-deprecated-button v-gl-modal.authKeyModal class="mt-2">{{
        $options.RESET_KEY
      }}</gl-deprecated-button>
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
