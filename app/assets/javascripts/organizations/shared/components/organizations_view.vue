<script>
import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';
import OrganizationsList from './list/organizations_list.vue';

export default {
  name: 'OrganizationsView',
  i18n: {
    emptyStateTitle: s__('Organization|Get started with organizations'),
    emptyStateDescription: s__(
      'Organization|Create an organization to contain all of your groups and projects.',
    ),
    emptyStateButtonText: s__('Organization|New organization'),
  },
  components: {
    GlLoadingIcon,
    OrganizationsList,
    GlEmptyState,
  },
  inject: ['newOrganizationUrl', 'organizationsEmptyStateSvgPath'],
  props: {
    organizations: {
      type: Object,
      required: false,
      default: () => {},
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    nodes() {
      return this.organizations.nodes || [];
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="loading" class="gl-mt-5" size="md" />
  <organizations-list
    v-else-if="nodes.length"
    :organizations="organizations"
    class="gl-border-t"
    @prev="$emit('prev', $event)"
    @next="$emit('next', $event)"
  />
  <gl-empty-state
    v-else
    :svg-height="144"
    :svg-path="organizationsEmptyStateSvgPath"
    :title="$options.i18n.emptyStateTitle"
    :description="$options.i18n.emptyStateDescription"
    :primary-button-link="newOrganizationUrl"
    :primary-button-text="$options.i18n.emptyStateButtonText"
  />
</template>
