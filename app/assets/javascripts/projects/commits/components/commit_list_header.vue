<script>
export default {
  name: 'CommitHeader',
  inject: ['projectPath'],
};
</script>

<template>
  <div>
    <h1 class="gl-text-size-h1">{{ __('Commits') }}</h1>
  </div>
</template>
