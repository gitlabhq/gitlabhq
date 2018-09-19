<script>
  export default {
    props: {
      shortToken: {
        type: String,
        required: false,
        default: null,
      },

      variables: {
        type: Object,
        required: false,
        default: () => ({}),
      },
    },
    data() {
      return {
        areVariablesVisible: false,
      };
    },
    computed: {
      hasVariables() {
        return Object.keys(this.variables).length > 0;
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
    <h4 class="title">
      {{ __('Trigger') }}
    </h4>

    <p
      v-if="shortToken"
      class="js-short-token"
    >
      <span class="build-light-text">
        {{ __('Token') }}
      </span>
      {{ shortToken }}
    </p>

    <p v-if="hasVariables">
      <button
        type="button"
        class="btn btn-default group js-reveal-variables"
        @click="revealVariables"
      >
        {{ __('Reveal Variables') }}
      </button>

    </p>

    <dl
      v-if="areVariablesVisible"
      class="js-build-variables trigger-build-variables"
    >
      <template
        v-for="(value, key) in variables"
      >
        <dt
          :key="`${key}-variable`"
          class="js-build-variable trigger-build-variable"
        >
          {{ key }}
        </dt>

        <dd
          :key="`${key}-value`"
          class="js-build-value trigger-build-value"
        >
          {{ value }}
        </dd>
      </template>
    </dl>
  </div>
</template>
