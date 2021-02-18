<script>
import ConfigurationTable from './configuration_table.vue';

export default {
  components: {
    ConfigurationTable,
  },
};
</script>

<template>
  <article>
    <header>
      <h4 class="gl-my-5">
        {{ __('Security Configuration') }}
      </h4>
      <h5 class="gl-font-lg gl-mt-7">
        {{ s__('SecurityConfiguration|Testing & Compliance') }}
      </h5>
    </header>
    <configuration-table />
  </article>
</template>
