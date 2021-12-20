<script>
import { GlFormGroup, GlFormCheckbox } from '@gitlab/ui';
import { mapGetters } from 'vuex';

export default {
  name: 'ActiveCheckbox',
  components: {
    GlFormGroup,
    GlFormCheckbox,
  },
  data() {
    return {
      activated: false,
    };
  },
  computed: {
    ...mapGetters(['isInheriting', 'propsSource']),
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
    <gl-form-checkbox
      v-model="activated"
      class="gl-display-block"
      :disabled="isInheriting"
      @change="onChange"
    >
      {{ __('Active') }}
    </gl-form-checkbox>
  </gl-form-group>
</template>
