<script>
export default {
  name: 'ReplyPlaceholder',
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
    {{ s__('MergeRequests|Reply...') }}
  </button>
</template>
