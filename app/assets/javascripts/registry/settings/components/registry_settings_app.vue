<script>
import { mapActions, mapState } from 'vuex';
import { GlAlert } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';

import { FETCH_SETTINGS_ERROR_MESSAGE } from '../../shared/constants';

import SettingsForm from './settings_form.vue';

export default {
  components: {
    SettingsForm,
    GlAlert,
  },
  computed: {
    ...mapState(['isDisabled']),
    notAvailableMessage() {
      return sprintf(
        s__(
          'ContainerRegistry|Currently, the Container Registry tag expiration feature is not available for projects created before GitLab version 12.8. For updates and more information, visit Issue %{linkStart}#196124%{linkEnd}',
        ),
        {
          linkStart:
            '<a href="https://gitlab.com/gitlab-org/gitlab/issues/196124" target="_blank" rel="noopener noreferrer">',
          linkEnd: '</a>',
        },
        false,
      );
    },
  },
  mounted() {
    this.fetchSettings().catch(() =>
      this.$toast.show(FETCH_SETTINGS_ERROR_MESSAGE, { type: 'error' }),
    );
  },
  methods: {
    ...mapActions(['fetchSettings']),
  },
};
</script>

<template>
  <div>
    <p>
      {{ s__('ContainerRegistry|Tag expiration policy is designed to:') }}
    </p>
    <ul>
      <li>{{ s__('ContainerRegistry|Keep and protect the images that matter most.') }}</li>
      <li>
        {{
          s__(
            "ContainerRegistry|Automatically remove extra images that aren't designed to be kept.",
          )
        }}
      </li>
    </ul>
    <settings-form v-if="!isDisabled" />
    <gl-alert v-else :dismissible="false">
      <p v-html="notAvailableMessage"></p>
    </gl-alert>
  </div>
</template>
