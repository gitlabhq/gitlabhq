<script>
import { mapGetters } from 'vuex';
import eventHub from '../event_hub';
import { GlFormGroup, GlToggle } from '@gitlab/ui';

export default {
  name: 'ActiveToggle',
  components: {
    GlFormGroup,
    GlToggle,
  },
  props: {
    initialActivated: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      activated: this.initialActivated,
    };
  },
  computed: {
    ...mapGetters(['isInheriting']),
  },
  mounted() {
    // Initialize view
    this.$nextTick(() => {
      this.onToggle(this.activated);
    });
  },
  methods: {
    onToggle(e) {
      eventHub.$emit('toggle', e);
    },
  },
};
</script>

<template>
  <gl-form-group :label="__('Enable integration')" label-for="service[active]">
    <gl-toggle
      v-model="activated"
      name="service[active]"
      class="gl-display-block gl-line-height-0"
      :disabled="isInheriting"
      @change="onToggle"
    />
  </gl-form-group>
</template>
