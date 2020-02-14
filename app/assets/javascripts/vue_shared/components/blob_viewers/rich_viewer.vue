<script>
import ViewerMixin from './mixins';

export default {
  mixins: [ViewerMixin],
};
</script>
<template>
  <div v-html="content"></div>
</template>
