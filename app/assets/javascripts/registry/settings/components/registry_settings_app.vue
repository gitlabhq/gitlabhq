<script>
import { mapActions } from 'vuex';
import { FETCH_SETTINGS_ERROR_MESSAGE } from '../constants';

import SettingsForm from './settings_form.vue';

export default {
  components: {
    SettingsForm,
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
    <settings-form ref="settings-form" />
  </div>
</template>
