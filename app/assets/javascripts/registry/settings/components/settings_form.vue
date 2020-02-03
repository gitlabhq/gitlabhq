<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import Tracking from '~/tracking';
import {
  UPDATE_SETTINGS_ERROR_MESSAGE,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
} from '../../shared/constants';
import { mapComputed } from '~/vuex_shared/bindings';
import ExpirationPolicyForm from '../../shared/components/expiration_policy_form.vue';

export default {
  components: {
    ExpirationPolicyForm,
  },
  mixins: [Tracking.mixin()],
  labelsConfig: {
    cols: 3,
    align: 'right',
  },
  data() {
    return {
      tracking: {
        label: 'docker_container_retention_and_expiration_policies',
      },
    };
  },
  computed: {
    ...mapState(['formOptions', 'isLoading']),
    ...mapGetters({ isEdited: 'getIsEdited' }),
    ...mapComputed([{ key: 'settings', getter: 'getSettings' }], 'updateSettings'),
  },
  methods: {
    ...mapActions(['resetSettings', 'saveSettings']),
    reset() {
      this.track('reset_form');
      this.resetSettings();
    },
    submit() {
      this.track('submit_form');
      this.saveSettings()
        .then(() => this.$toast.show(UPDATE_SETTINGS_SUCCESS_MESSAGE, { type: 'success' }))
        .catch(() => this.$toast.show(UPDATE_SETTINGS_ERROR_MESSAGE, { type: 'error' }));
    },
  },
};
</script>

<template>
  <expiration-policy-form
    v-model="settings"
    :form-options="formOptions"
    :is-loading="isLoading"
    :disable-cancel-button="!isEdited"
    @submit="submit"
    @reset="reset"
  />
</template>
