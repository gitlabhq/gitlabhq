<script>
import Icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  components: {
    Icon,
  },
  directives: {
    tooltip,
  },
  props: {
    value: {
      type: Boolean,
      required: true,
    },
    helpPath: {
      type: String,
      required: false,
      default: '',
    },
    isDisabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div class="inline">
    <label>
      <input
        :checked="value"
        :disabled="isDisabled"
        type="checkbox"
        name="squash"
        class="qa-squash-checkbox js-squash-checkbox"
        @change="$emit('input', $event.target.checked)"
      />
      {{ __('Squash commits') }}
    </label>
    <a
      v-if="helpPath"
      v-tooltip
      :href="helpPath"
      data-title="About this feature"
      data-placement="bottom"
      target="_blank"
      rel="noopener noreferrer nofollow"
      data-container="body"
    >
      <icon name="question-o" />
    </a>
  </div>
</template>
