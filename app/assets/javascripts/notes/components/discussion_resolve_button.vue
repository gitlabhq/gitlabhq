<script>
export default {
  name: 'ResolveDiscussionButton',
  props: {
    isResolving: {
      type: Boolean,
      required: false,
      default: false,
    },
    buttonTitle: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <button ref="button" type="button" class="btn btn-default ml-sm-2" @click="$emit('onClick')">
    <i
      v-if="isResolving"
      ref="isResolvingIcon"
      aria-hidden="true"
      class="fa fa-spinner fa-spin"
    ></i>
    {{ buttonTitle }}
  </button>
</template>
