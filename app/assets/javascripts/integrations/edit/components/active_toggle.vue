<script>
import eventHub from '../event_hub';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { GlFormGroup, GlToggle } from '@gitlab/ui';

export default {
  name: 'ActiveToggle',
  components: {
    GlFormGroup,
    GlToggle,
  },
  mixins: [glFeatureFlagsMixin()],
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
  <div v-if="glFeatures.integrationFormRefactor">
    <gl-form-group :label="__('Enable integration')" label-for="service[active]">
      <gl-toggle
        v-model="activated"
        name="service[active]"
        class="gl-display-block gl-line-height-0"
        @change="onToggle"
      />
    </gl-form-group>
  </div>
  <div v-else>
    <div class="form-group row" role="group">
      <label for="service[active]" class="col-form-label col-sm-2">{{ __('Active') }}</label>
      <div class="col-sm-10 pt-1">
        <gl-toggle v-model="activated" name="service[active]" @change="onToggle" />
      </div>
    </div>
  </div>
</template>
