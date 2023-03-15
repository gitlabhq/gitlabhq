<script>
import { GlButton } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { getParameterByName, updateHistory, mergeUrlParams } from '~/lib/utils/url_utility';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_RUNNER } from '~/graphql_shared/constants';
import runnerForRegistrationQuery from '../graphql/register/runner_for_registration.query.graphql';
import {
  I18N_FETCH_ERROR,
  PARAM_KEY_PLATFORM,
  DEFAULT_PLATFORM,
  STATUS_ONLINE,
  RUNNER_REGISTRATION_POLLING_INTERVAL_MS,
} from '../constants';
import RegistrationInstructions from '../components/registration/registration_instructions.vue';
import PlatformsDrawer from '../components/registration/platforms_drawer.vue';
import { captureException } from '../sentry_utils';

export default {
  name: 'AdminRegisterRunnerApp',
  components: {
    GlButton,
    RegistrationInstructions,
    PlatformsDrawer,
  },
  props: {
    runnerId: {
      type: String,
      required: true,
    },
    runnersPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      platform: getParameterByName(PARAM_KEY_PLATFORM) || DEFAULT_PLATFORM,
      runner: null,
      isDrawerOpen: false,
    };
  },
  apollo: {
    runner: {
      query: runnerForRegistrationQuery,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_CI_RUNNER, this.runnerId),
        };
      },
      error(error) {
        createAlert({ message: I18N_FETCH_ERROR });
        captureException({ error, component: this.$options.name });
      },
      pollInterval() {
        if (this.runner?.status === STATUS_ONLINE) {
          // stop polling
          return 0;
        }
        return RUNNER_REGISTRATION_POLLING_INTERVAL_MS;
      },
    },
  },
  watch: {
    platform(platform) {
      updateHistory({
        url: mergeUrlParams({ [PARAM_KEY_PLATFORM]: platform }, window.location.href),
      });
    },
  },
  methods: {
    onSelectPlatform(platform) {
      this.platform = platform;
    },
    onToggleDrawer(val = !this.isDrawerOpen) {
      this.isDrawerOpen = val;
    },
  },
};
</script>
<template>
  <div>
    <registration-instructions
      :runner="runner"
      :platform="platform"
      :loading="$apollo.queries.runner.loading"
      @toggleDrawer="onToggleDrawer"
    >
      <template #runner-list-name>{{ s__('Runners|Admin area › Runners') }}</template>
    </registration-instructions>

    <platforms-drawer
      :platform="platform"
      :open="isDrawerOpen"
      @selectPlatform="onSelectPlatform"
      @close="onToggleDrawer(false)"
    />

    <gl-button :href="runnersPath" variant="confirm">{{
      s__('Runners|Go to runners page')
    }}</gl-button>
  </div>
</template>
