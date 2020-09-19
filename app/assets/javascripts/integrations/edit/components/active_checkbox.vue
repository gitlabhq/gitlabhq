<script>
import { mapGetters } from 'vuex';
import { GlFormGroup, GlFormCheckbox } from '@gitlab/ui';
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
      eventHub.$emit('toggle', e);
    },
  },
};
</script>

<template>
  <gl-form-group :label="__('Enable integration')" label-for="service[active]">
    <input name="service[active]" type="hidden" :value="activated || false" />
    <gl-form-checkbox
      v-model="activated"
      name="service[active]"
      class="gl-display-block gl-line-height-0"
      :disabled="isInheriting"
      @change="onChange"
    >
      {{ __('Active') }}
    </gl-form-checkbox>
  </gl-form-group>
</template>
