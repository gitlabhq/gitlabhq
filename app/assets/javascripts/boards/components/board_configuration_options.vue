<script>
import { GlFormCheckbox } from '@gitlab/ui';

export default {
  components: {
    GlFormCheckbox,
  },
  props: {
    hideBacklogList: {
      type: Boolean,
      required: true,
    },
    hideClosedList: {
      type: Boolean,
      required: true,
    },
    readonly: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-mb-5">
    <label class="label-bold gl-text-lg" for="board-new-name">
      {{ __('List options') }}
    </label>
    <p class="gl-mb-3 gl-text-subtle">
      {{ __('Configure which lists are shown for anyone who visits this board') }}
    </p>
    <gl-form-checkbox
      :checked="!hideBacklogList"
      :disabled="readonly"
      data-testid="backlog-list-checkbox"
      @change="$emit('update:hideBacklogList', !hideBacklogList)"
      >{{ __('Show the Open list') }}
    </gl-form-checkbox>
    <gl-form-checkbox
      :checked="!hideClosedList"
      :disabled="readonly"
      data-testid="closed-list-checkbox"
      @change="$emit('update:hideClosedList', !hideClosedList)"
      >{{ __('Show the Closed list') }}
    </gl-form-checkbox>
  </div>
</template>
