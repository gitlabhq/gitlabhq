<script>
import { GlAlert } from '@gitlab/ui';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';

export default {
  name: 'LoadOrErrorOrShow',
  components: {
    PackagesListLoader,
    GlAlert,
  },
  props: {
    errorMessage: {
      type: String,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <packages-list-loader v-if="isLoading" />
  <gl-alert v-else-if="errorMessage" variant="danger" :dismissible="false">
    {{ errorMessage }}
  </gl-alert>
  <div v-else>
    <slot></slot>
  </div>
</template>
