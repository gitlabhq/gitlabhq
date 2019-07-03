<script>
export default {
  name: 'ReplyPlaceholder',
  props: {
    buttonText: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <button
    ref="button"
    type="button"
    class="js-vue-discussion-reply btn btn-text-field"
    :title="s__('MergeRequests|Add a reply')"
    @click="$emit('onClick')"
  >
    {{ buttonText }}
  </button>
</template>
