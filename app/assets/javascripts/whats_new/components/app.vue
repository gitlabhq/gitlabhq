<script>
import { mapState, mapActions } from 'vuex';
import { GlDrawer } from '@gitlab/ui';

export default {
  components: {
    GlDrawer,
  },
  computed: {
    ...mapState(['open']),
  },
  methods: {
    ...mapActions(['closeDrawer']),
  },
};
</script>

<template>
  <div>
    <gl-drawer class="mt-6" :open="open" @close="closeDrawer">
      <template #header>
        <h4>{{ __("What's new at GitLab") }}</h4>
      </template>
      <template>
        <div></div>
      </template>
    </gl-drawer>
  </div>
</template>
