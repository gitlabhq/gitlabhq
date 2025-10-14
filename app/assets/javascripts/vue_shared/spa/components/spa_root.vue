<script>
export default {};
</script>
<template>
  <div id="single-page-app">
    <router-view #default="{ Component }">
      <component :is="Component" />
    </router-view>
  </div>
</template>
