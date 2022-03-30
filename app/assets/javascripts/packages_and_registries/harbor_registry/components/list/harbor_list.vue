<script>
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import HarborListRow from '~/packages_and_registries/harbor_registry/components/list/harbor_list_row.vue';

export default {
  name: 'HarborList',
  components: {
    RegistryList,
    HarborListRow,
  },
  props: {
    images: {
      type: Array,
      required: true,
    },
    metadataLoading: {
      type: Boolean,
      default: false,
      required: false,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <registry-list
    :items="images"
    :hidden-delete="true"
    :pagination="pageInfo"
    id-property="name"
    @prev-page="$emit('prev-page')"
    @next-page="$emit('next-page')"
  >
    <template #default="{ item }">
      <harbor-list-row :item="item" :metadata-loading="metadataLoading" />
    </template>
  </registry-list>
</template>
