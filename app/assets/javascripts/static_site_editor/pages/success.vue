<script>
import { mapState } from 'vuex';
import SavedChangesMessage from '../components/saved_changes_message.vue';
import { HOME_ROUTE } from '../router/constants';

export default {
  components: {
    SavedChangesMessage,
  },
  computed: {
    ...mapState(['savedContentMeta', 'returnUrl']),
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
      :return-url="returnUrl"
    />
  </div>
</template>
