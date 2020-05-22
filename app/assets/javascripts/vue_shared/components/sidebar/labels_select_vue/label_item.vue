<script>
import { GlIcon, GlLink } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    label: {
      type: Object,
      required: true,
    },
    isLabelSet: {
      type: Boolean,
      required: true,
    },
    highlight: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isSet: this.isLabelSet,
    };
  },
  computed: {
    labelBoxStyle() {
      return {
        backgroundColor: this.label.color,
      };
    },
  },
  watch: {
    /**
     * This watcher assures that if user used
     * `Enter` key to set/unset label, changes
     * are reflected here too.
     */
    isLabelSet(value) {
      this.isSet = value;
    },
  },
  methods: {
    handleClick() {
      this.isSet = !this.isSet;
      this.$emit('clickLabel', this.label);
    },
  },
};
</script>

<template>
  <gl-link
    class="d-flex align-items-baseline text-break-word label-item"
    :class="{ 'is-focused': highlight }"
    @click="handleClick"
  >
    <gl-icon v-show="isSet" name="mobile-issue-close" class="mr-2 align-self-center" />
    <span v-show="!isSet" data-testid="no-icon" class="mr-3 pr-2"></span>
    <span class="dropdown-label-box" data-testid="label-color-box" :style="labelBoxStyle"></span>
    <span>{{ label.title }}</span>
  </gl-link>
</template>
