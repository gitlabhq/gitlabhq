<script>
import { GlFormGroup, GlFormCheckbox } from '@gitlab/ui';
import { mapState } from 'pinia';
import { useIntegrationForm } from '../store';

export default {
  name: 'ActiveCheckbox',
  components: {
    GlFormGroup,
    GlFormCheckbox,
  },
  emits: ['toggle-integration-active'],
  data() {
    return {
      activated: false,
    };
  },
  computed: {
    ...mapState(useIntegrationForm, ['isInheriting', 'propsSource', 'customState']),
    disabled() {
      return this.isInheriting || this.customState.activateDisabled;
    },
  },
  mounted() {
    this.activated = this.propsSource.initialActivated;
    this.onChange(this.activated);
  },
  methods: {
    onChange(isChecked) {
      this.$emit('toggle-integration-active', isChecked);
    },
  },
};
</script>

<template>
  <gl-form-group :label="__('Enable integration')" label-for="service[active]">
    <input name="service[active]" type="hidden" :value="activated || false" />
    <gl-form-checkbox v-model="activated" class="gl-block" :disabled="disabled" @change="onChange">
      {{ __('Active') }}
    </gl-form-checkbox>
  </gl-form-group>
</template>
