<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { s__ } from '~/locale';
import folderQuery from '../graphql/queries/folder.query.graphql';
import EnvironmentItem from '../components/new_environment_item.vue';

export default {
  components: {
    GlSkeletonLoader,
    EnvironmentItem,
  },
  props: {
    folderName: {
      type: String,
      required: true,
    },
    folderPath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    folder: {
      query: folderQuery,
      variables() {
        return {
          environment: this.environmentQueryData,
          scope: '',
          search: '',
          perPage: 10,
        };
      },
    },
  },
  computed: {
    environmentQueryData() {
      return { folderPath: this.folderPath };
    },
    environments() {
      return this.folder?.environments;
    },
    isLoading() {
      return this.$apollo.queries.folder.loading;
    },
  },
  i18n: {
    pageTitle: s__('Environments|Environments'),
  },
};
</script>
<template>
  <div>
    <h4 class="gl-font-weight-normal" data-testid="folder-name">
      {{ $options.i18n.pageTitle }} /
      <b>{{ folderName }}</b>
    </h4>
    <div v-if="isLoading">
      <div
        v-for="n in 3"
        :key="`skeleton-box-${n}`"
        class="gl-border-gray-100 gl-border-t-solid gl-border-1 gl-py-5 gl-md-pl-7"
      >
        <gl-skeleton-loader :lines="2" />
      </div>
    </div>
    <environment-item
      v-for="environment in environments"
      :key="environment.name"
      :environment="environment"
      class="gl-border-gray-100 gl-border-t-solid gl-border-1 gl-pt-3"
      in-folder
    />
  </div>
</template>
