<script>
import { mapState, mapActions } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import SettingsForm from './settings_form.vue';

export default {
  components: {
    GlLoadingIcon,
    SettingsForm,
  },
  computed: {
    ...mapState({
      isLoading: 'isLoading',
    }),
  },
  mounted() {
    this.fetchSettings();
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
    <gl-loading-icon v-if="isLoading" ref="loading-icon" />
    <settings-form v-else ref="settings-form" />
  </div>
</template>
