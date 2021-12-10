<script>
export default {
  props: {
    language: {
      type: String,
      required: true,
    },
    tokens: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <span class="line" :lang="language">
    <span v-for="(token, tokenIndex) in tokens" :key="tokenIndex" :class="token.class">{{
      token.value
    }}</span>
    <br />
  </span>
</template>
