<script>
import { GlDrawer, GlFormGroup, GlFormSelect, GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';

import {
  DEFAULT_PLATFORM,
  MACOS_PLATFORM,
  LINUX_PLATFORM,
  WINDOWS_PLATFORM,
  INSTALL_HELP_URL,
} from '../../constants';
import { installScript, platformArchitectures } from './utils';

import CliCommand from './cli_command.vue';

export default {
  components: {
    GlDrawer,
    GlFormGroup,
    GlFormSelect,
    GlIcon,
    GlLink,
    GlSprintf,
    CliCommand,
  },
  props: {
    open: {
      type: Boolean,
      required: true,
    },
    platform: {
      type: String,
      required: false,
      default: DEFAULT_PLATFORM,
    },
  },
  data() {
    return {
      selectedPlatform: this.platform,
      selectedArchitecture: null,
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    architectureOptions() {
      return platformArchitectures({ platform: this.selectedPlatform });
    },
    script() {
      return installScript({
        platform: this.selectedPlatform,
        architecture: this.selectedArchitecture,
      });
    },
  },
  watch: {
    selectedPlatform() {
      this.selectedArchitecture =
        this.architectureOptions.find((value) => value === this.selectedArchitecture) ||
        this.architectureOptions[0];

      this.$emit('selectPlatform', this.selectedPlatform);
    },
  },
  created() {
    [this.selectedArchitecture] = this.architectureOptions;
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
  },
  platformOptions: [
    /* eslint-disable @gitlab/require-i18n-strings */
    { value: LINUX_PLATFORM, text: 'Linux' },
    { value: MACOS_PLATFORM, text: 'macOS' },
    { value: WINDOWS_PLATFORM, text: 'Windows' },
    /* eslint-enable @gitlab/require-i18n-strings */
  ],
  INSTALL_HELP_URL,
  DRAWER_Z_INDEX,
};
</script>
<template>
  <gl-drawer
    :open="open"
    :header-height="getDrawerHeaderHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    data-testid="runner-platforms-drawer"
    @close="onClose"
  >
    <template #title>
      <h2 class="gl-my-0 gl-font-size-h2 gl-line-height-24">
        {{ s__('Runners|Install GitLab Runner') }}
      </h2>
    </template>
    <div>
      <p>{{ s__('Runners|Select platform specifications to install GitLab Runner.') }}</p>

      <gl-form-group :label="s__('Runners|Environment')" label-for="runner-environment-select">
        <gl-form-select
          id="runner-environment-select"
          v-model="selectedPlatform"
          :options="$options.platformOptions"
        />
      </gl-form-group>

      <gl-form-group :label="s__('Runners|Architecture')" label-for="runner-architecture-select">
        <gl-form-select
          id="runner-architecture-select"
          v-model="selectedArchitecture"
          :options="architectureOptions"
        />
      </gl-form-group>

      <cli-command :command="script" />

      <p>
        <gl-sprintf
          :message="
            s__('Runners|See more %{linkStart}installation methods and architectures%{linkEnd}.')
          "
        >
          <template #link="{ content }">
            <gl-link :href="$options.INSTALL_HELP_URL">
              {{ content }} <gl-icon name="external-link" />
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
    </div>
  </gl-drawer>
</template>
