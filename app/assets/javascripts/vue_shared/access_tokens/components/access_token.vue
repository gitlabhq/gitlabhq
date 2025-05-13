<script>
import { GlAlert } from '@gitlab/ui';
import { mapActions, mapState } from 'pinia';
import InputCopyToggleVisibility from '~/vue_shared/components/input_copy_toggle_visibility/input_copy_toggle_visibility.vue';
import { useAccessTokens } from '../stores/access_tokens';

export default {
  components: { GlAlert, InputCopyToggleVisibility },
  computed: {
    ...mapState(useAccessTokens, ['token']),
    formInputGroupProps() {
      return {
        'data-testid': this.$options.inputId,
        id: this.$options.inputId,
        name: this.$options.inputId,
      };
    },
  },
  methods: {
    ...mapActions(useAccessTokens, ['setToken']),
  },
  inputId: 'access-token-field',
};
</script>

<template>
  <gl-alert variant="success" class="gl-mb-5" @dismiss="setToken(null)">
    <input-copy-toggle-visibility
      :copy-button-title="s__('AccessTokens|Copy token')"
      :label="s__('AccessTokens|Your token')"
      :label-for="$options.inputId"
      :value="token"
      :form-input-group-props="formInputGroupProps"
      readonly
      size="lg"
      class="gl-mb-0"
    >
      <template #description>
        {{ s__("AccessTokens|Make sure you save it - you won't be able to access it again.") }}
      </template>
    </input-copy-toggle-visibility>
  </gl-alert>
</template>
