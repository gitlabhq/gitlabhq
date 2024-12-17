<script>
import { GlButton, GlCollapsibleListbox, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import { REGISTRATION_TOKEN_PLACEHOLDER } from '../constants';
import getRunnerSetupInstructionsQuery from '../graphql/get_runner_setup.query.graphql';

export default {
  components: {
    GlButton,
    GlCollapsibleListbox,
    GlLoadingIcon,
    ModalCopyButton,
  },
  props: {
    platform: {
      type: Object,
      required: false,
      default: null,
    },
    registrationToken: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      selectedArchName: this.platform?.architectures[0]?.name || null,
      instructions: null,
    };
  },
  apollo: {
    instructions: {
      query: getRunnerSetupInstructionsQuery,
      skip() {
        return !this.platform || !this.selectedArchitecture;
      },
      variables() {
        return {
          platform: this.platform.name,
          architecture: this.selectedArchitecture.name,
        };
      },
      update(data) {
        return data?.runnerSetup;
      },
      error() {
        this.$emit('error');
      },
    },
  },
  computed: {
    architectures() {
      return this.platform?.architectures || [];
    },
    selectedArchitecture() {
      return this.architectures.find(({ name }) => name === this.selectedArchName) || null;
    },
    binaryUrl() {
      return this.selectedArchitecture?.downloadLocation;
    },
    registerInstructionsWithToken() {
      const { registerInstructions } = this.instructions || {};

      if (this.registrationToken) {
        return registerInstructions?.replace(
          REGISTRATION_TOKEN_PLACEHOLDER,
          this.registrationToken,
        );
      }
      return registerInstructions;
    },
    listboxItems() {
      return this.architectures.map(({ name }) => {
        return { text: name, value: name };
      });
    },
  },
  watch: {
    platform() {
      // reset selection if architecture is not in this list
      const arch = this.architectures.find(({ name }) => name === this.selectedArchName);
      if (!arch) {
        this.selectedArchName = this.architectures[0]?.name || null;
      }
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
  },
  i18n: {
    architecture: s__('Runners|Architecture'),
    downloadInstallBinary: s__('Runners|Download and install binary'),
    downloadLatestBinary: s__('Runners|Download latest binary'),
    registerRunnerCommand: s__('Runners|Command to register runner'),
    copyInstructions: s__('Runners|Copy instructions'),
  },
};
</script>

<template>
  <div>
    <h5>
      {{ $options.i18n.architecture }}
      <gl-loading-icon v-if="$apollo.loading" size="sm" inline />
    </h5>

    <gl-collapsible-listbox v-model="selectedArchName" class="gl-mb-3" :items="listboxItems" />
    <div class="gl-mb-3 gl-items-center sm:gl-flex">
      <h5>{{ $options.i18n.downloadInstallBinary }}</h5>
      <gl-button
        v-if="binaryUrl"
        class="gl-ml-auto"
        :href="binaryUrl"
        download
        icon="download"
        data-testid="binary-download-button"
      >
        {{ $options.i18n.downloadLatestBinary }}
      </gl-button>
    </div>

    <template v-if="instructions">
      <div class="gl-flex">
        <pre class="gl-bg-gray gl-grow gl-whitespace-pre-line" data-testid="binary-instructions">{{
          instructions.installInstructions
        }}</pre>
        <modal-copy-button
          :title="$options.i18n.copyInstructions"
          :text="instructions.installInstructions"
          :modal-id="$options.modalId"
          css-classes="gl-self-start gl-ml-2 gl-mt-2"
          category="tertiary"
        />
      </div>
      <h5 class="gl-mb-3">{{ $options.i18n.registerRunnerCommand }}</h5>
      <div class="gl-flex">
        <pre class="gl-bg-gray gl-grow gl-whitespace-pre-line" data-testid="register-command">{{
          registerInstructionsWithToken
        }}</pre>
        <modal-copy-button
          :title="$options.i18n.copyInstructions"
          :text="registerInstructionsWithToken"
          :modal-id="$options.modalId"
          css-classes="gl-self-start gl-ml-2 gl-mt-2"
          category="tertiary"
        />
      </div>
    </template>

    <footer class="gl-flex gl-justify-end gl-pt-3">
      <gl-button @click="onClose()">{{ __('Close') }}</gl-button>
    </footer>
  </div>
</template>
