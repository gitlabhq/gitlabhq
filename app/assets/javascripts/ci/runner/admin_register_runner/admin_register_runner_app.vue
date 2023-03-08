<script>
import { GlButton } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { createAlert } from '~/flash';
import { getParameterByName, updateHistory, mergeUrlParams } from '~/lib/utils/url_utility';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_RUNNER } from '~/graphql_shared/constants';
import runnerForRegistrationQuery from '../graphql/register/runner_for_registration.query.graphql';
import { I18N_FETCH_ERROR, PARAM_KEY_PLATFORM, DEFAULT_PLATFORM } from '../constants';
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
    },
  },
  computed: {
    description() {
      return this.runner?.description;
    },
    heading() {
      if (this.description) {
        return sprintf(s__('Runners|Register "%{runnerDescription}" runner'), {
          runnerDescription: this.description,
        });
      }
      return s__('Runners|Register runner');
    },
    ephemeralAuthenticationToken() {
      return this.runner?.ephemeralAuthenticationToken;
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
    <h1 class="gl-font-size-h1">{{ heading }}</h1>

    <registration-instructions
      :loading="$apollo.queries.runner.loading"
      :platform="platform"
      :token="ephemeralAuthenticationToken"
      @toggleDrawer="onToggleDrawer"
    />

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
