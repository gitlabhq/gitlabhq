<script>
import eventHub from '../event_hub';
import { GlToggle } from '@gitlab/ui';

export default {
  name: 'ActiveToggle',
  components: {
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
  <div>
    <div class="form-group row" role="group">
      <label for="service[active]" class="col-form-label col-sm-2">{{ __('Active') }}</label>
      <div class="col-sm-10 pt-1">
        <gl-toggle v-model="activated" name="service[active]" @change="onToggle" />
      </div>
    </div>
  </div>
</template>
