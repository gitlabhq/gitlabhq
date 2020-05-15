<script>
import savedContentMetaQuery from '../graphql/queries/saved_content_meta.query.graphql';
import appDataQuery from '../graphql/queries/app_data.query.graphql';
import SavedChangesMessage from '../components/saved_changes_message.vue';
import { HOME_ROUTE } from '../router/constants';

export default {
  components: {
    SavedChangesMessage,
  },
  apollo: {
    savedContentMeta: {
      query: savedContentMetaQuery,
    },
    appData: {
      query: appDataQuery,
    },
  },
  created() {
    if (!this.savedContentMeta) {
      this.$router.push(HOME_ROUTE);
    }
  },
};
</script>
<template>
  <div v-if="savedContentMeta" class="container">
    <saved-changes-message
      :branch="savedContentMeta.branch"
      :commit="savedContentMeta.commit"
      :merge-request="savedContentMeta.mergeRequest"
      :return-url="appData.returnUrl"
    />
  </div>
</template>
