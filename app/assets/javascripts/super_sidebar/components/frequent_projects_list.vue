<script>
import { s__ } from '~/locale';
import { MAX_FREQUENT_PROJECTS_COUNT } from '../constants';
import FrequentItemsList from './frequent_items_list.vue';
import NavItem from './nav_item.vue';

export default {
  MAX_FREQUENT_PROJECTS_COUNT,
  components: {
    FrequentItemsList,
    NavItem,
  },
  props: {
    username: {
      type: String,
      required: true,
    },
    viewAllLink: {
      type: String,
      required: true,
    },
  },
  computed: {
    storageKey() {
      return `${this.username}/frequent-projects`;
    },
    viewAllItem() {
      return {
        link: this.viewAllLink,
        title: s__('Navigation|View all projects'),
        icon: 'project',
      };
    },
  },
  i18n: {
    title: s__('Navigation|FREQUENT PROJECTS'),
    pristineText: s__('Navigation|Projects you visit often will appear here.'),
  },
};
</script>

<template>
  <frequent-items-list
    :title="$options.i18n.title"
    :storage-key="storageKey"
    :max-items="$options.MAX_FREQUENT_PROJECTS_COUNT"
  >
    <template #view-all-items>
      <nav-item :item="viewAllItem" />
    </template>
    <template #empty>
      {{ $options.i18n.pristineText }}
    </template>
  </frequent-items-list>
</template>
