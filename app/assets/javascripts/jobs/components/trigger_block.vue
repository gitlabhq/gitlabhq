<script>
import { GlButton } from '@gitlab/ui';

export default {
  components: {
    GlButton,
  },
  props: {
    trigger: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      areVariablesVisible: false,
    };
  },
  computed: {
    hasVariables() {
      return this.trigger.variables && this.trigger.variables.length > 0;
    },
  },
  methods: {
    revealVariables() {
      this.areVariablesVisible = true;
    },
  },
};
</script>

<template>
  <div class="build-widget block">
    <h4 class="title">{{ __('Trigger') }}</h4>

    <p v-if="trigger.short_token" class="js-short-token">
      <span class="build-light-text"> {{ __('Token') }} </span> {{ trigger.short_token }}
    </p>

    <p v-if="hasVariables">
      <gl-button
        v-if="!areVariablesVisible"
        type="button"
        class="btn btn-default group js-reveal-variables"
        @click="revealVariables"
      >
        {{ __('Reveal Variables') }}
      </gl-button>
    </p>

    <dl v-if="areVariablesVisible" class="js-build-variables trigger-build-variables">
      <template v-for="variable in trigger.variables">
        <dt :key="`${variable.key}-variable`" class="js-build-variable trigger-build-variable">
          {{ variable.key }}
        </dt>

        <dd :key="`${variable.key}-value`" class="js-build-value trigger-build-value">
          {{ variable.value }}
        </dd>
      </template>
    </dl>
  </div>
</template>
