<script>
import { __ } from '~/locale';

export default {
  name: 'ReplyPlaceholder',
  props: {
    placeholderText: {
      type: String,
      required: false,
      default: __('Reply…'),
    },
    labelText: {
      type: String,
      required: false,
      default: __('Reply to comment'),
    },
  },
};
</script>

<template>
  <textarea
    ref="textarea"
    rows="1"
    class="reply-placeholder-text-field js-vue-discussion-reply"
    :placeholder="placeholderText"
    :aria-label="labelText"
    @focus="$emit('focus')"
  ></textarea>
</template>
