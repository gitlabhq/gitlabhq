<script>
export default {
  name: 'SpaRoot',
};
</script>
<template>
  <div id="single-page-app">
    <router-view #default="{ Component }">
      <component :is="Component" />
    </router-view>
  </div>
</template>
