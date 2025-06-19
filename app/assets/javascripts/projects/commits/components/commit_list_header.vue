<script>
export default {
  name: 'CommitHeader',
  inject: ['projectPath'],
};
</script>

<template>
  <div>
    <h1 class="gl-text-size-h1">{{ projectPath }}</h1>
  </div>
</template>
