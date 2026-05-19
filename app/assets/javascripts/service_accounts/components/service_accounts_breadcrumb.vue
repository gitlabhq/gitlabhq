<script>
import { GlBreadcrumb } from '@gitlab/ui';
import { s__ } from '~/locale';
import { ROUTES } from '../constants';

export default {
  name: 'ServiceAccountsBreadcrumb',
  components: {
    GlBreadcrumb,
  },
  props: {
    staticBreadcrumbs: {
      type: Array,
      required: true,
    },
  },
  computed: {
    breadcrumbs() {
      const breadcrumbs = [
        ...this.staticBreadcrumbs,
        {
          text: s__('ServiceAccounts|Service accounts'),
          to: '/',
        },
      ];

      if (this.$route.name === ROUTES.accessTokens) {
        breadcrumbs.push({
          text: s__('ServiceAccounts|Personal access tokens'),
          to: this.$route.path,
        });
      }

      return breadcrumbs;
    },
  },
};
</script>

<template>
  <gl-breadcrumb :items="breadcrumbs" />
</template>
