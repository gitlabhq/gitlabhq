<script>
import { GlFormGroup, GlFormCheckbox } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { TOGGLE_INTEGRATION_EVENT } from '~/integrations/constants';
import eventHub from '../event_hub';

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
    // Initialize view
    this.$nextTick(() => {
      this.onChange(this.activated);
    });
  },
  methods: {
    onChange(e) {
      eventHub.$emit(TOGGLE_INTEGRATION_EVENT, e);
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
