<script>
import { GlButton } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import OrganizationsView from './organizations_view.vue';

export default {
  name: 'OrganizationsIndexApp',
  i18n: {
    organizations: __('Organizations'),
    newOrganization: s__('Organization|New organization'),
  },
  components: {
    GlButton,
    OrganizationsView,
  },
  inject: ['newOrganizationUrl'],
};
</script>

<template>
  <section>
    <div class="gl-display-flex gl-align-items-center">
      <h1 class="gl-my-4 gl-font-size-h-display">{{ $options.i18n.organizations }}</h1>
      <div class="gl-ml-auto">
        <gl-button :href="newOrganizationUrl" variant="confirm">{{
          $options.i18n.newOrganization
        }}</gl-button>
      </div>
    </div>
    <organizations-view />
  </section>
</template>
