<script>
export default {
  name: 'StageNavItem',
  props: {
    isDefaultStage: {
      type: Boolean,
      default: false,
      required: false,
    },
    isActive: {
      type: Boolean,
      default: false,
      required: false,
    },
    isUserAllowed: {
      type: Boolean,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      default: '',
      required: false,
    },
    canEdit: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    hasValue() {
      return this.value && this.value.length > 0;
    },
  },
};
</script>

<template>
  <li @click="$emit('select')">
    <div
      :class="{ active: isActive }"
      class="stage-nav-item d-flex pl-4 pr-4 m-0 mb-1 ml-2 rounded border-color-default border-style-solid border-width-1px"
    >
      <div class="stage-nav-item-cell stage-name p-0" :class="{ 'font-weight-bold': isActive }">
        {{ title }}
      </div>
      <div class="stage-nav-item-cell stage-median mr-4">
        <template v-if="isUserAllowed">
          <span v-if="hasValue">{{ value }}</span>
          <span v-else class="stage-empty">{{ __('Not enough data') }}</span>
        </template>
        <template v-else>
          <span class="not-available">{{ __('Not available') }}</span>
        </template>
      </div>
    </div>
  </li>
</template>
