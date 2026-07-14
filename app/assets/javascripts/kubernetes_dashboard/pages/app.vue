<script>
import PageTitle from '../components/page_title.vue';

export default {
  name: 'KubernetesDashboardApp',
  components: { PageTitle },
};
</script>
<template>
  <div class="gl-mt-5">
    <page-title> {{ $route.meta.title }} </page-title>
    <router-view />
  </div>
</template>
