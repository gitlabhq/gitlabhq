<script>
import PageTitle from '../components/page_title.vue';

export default {
  components: { PageTitle },
};
</script>
<template>
  <div class="gl-mt-5">
    <page-title> {{ $route.meta.title }} </page-title>
  </div>
</template>
