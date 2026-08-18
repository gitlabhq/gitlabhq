<script>
export default {
  name: 'DuoQuestionNote',
  // The EE component's props are passed in regardless of edition. Without this
  // they land on the root element as attributes, including `[object Object]`
  // for the note and replies.
  inheritAttrs: false,
};
</script>

<template>
  <!-- Duo clarifying questions are an EE feature, so this renders nothing in FOSS. -->
  <div></div>
</template>
