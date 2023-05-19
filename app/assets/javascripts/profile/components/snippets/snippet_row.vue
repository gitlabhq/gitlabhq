<script>
export default {
  name: 'SnippetRow',
  props: {
    snippet: {
      type: Object,
      required: true,
    },
    userInfo: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    {{ snippet.title }}
  </div>
</template>
