<script>
  export default {
    props: {
      time: {
        type: Object,
        required: false,
        default: () => ({}),
      },
    },
    computed: {
      hasData() {
        return Object.keys(this.time).length;
      },
    },
  };
</script>
<template>
  <span class="total-time">
    <template v-if="hasData">
      <template v-if="time.days">
        {{ time.days }}
        <span>
          {{ n__('day', 'days', time.days) }}
        </span>
      </template>
      <template v-if="time.hours">
        {{ time.hours }}
        <span>
          {{ n__('Time|hr', 'Time|hrs', time.hours) }}
        </span>
      </template>
      <template v-if="time.mins && !time.days">
        {{ time.mins }}
        <span>
          {{ n__('Time|min', 'Time|mins', time.mins) }}
        </span>
      </template>
      <template v-if="time.seconds && hasData === 1 || time.seconds === 0">
        {{ time.seconds }}
        <span>
          {{ s__('Time|s') }}
        </span>
      </template>
    </template>
    <template v-else>
      --
    </template>
  </span>
</template>
