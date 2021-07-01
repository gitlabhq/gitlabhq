<script>
import { mapActions, mapGetters } from 'vuex';
import PreviewDropdown from './preview_dropdown.vue';
import PublishButton from './publish_button.vue';

export default {
  components: {
    PreviewDropdown,
    PublishButton,
  },
  computed: {
    ...mapGetters(['isNotesFetched']),
    ...mapGetters('batchComments', ['draftsCount']),
  },
  watch: {
    isNotesFetched() {
      if (this.isNotesFetched) {
        this.expandAllDiscussions();
      }
    },
  },
  methods: {
    ...mapActions('batchComments', ['expandAllDiscussions']),
  },
};
</script>
<template>
  <div v-show="draftsCount > 0">
    <nav class="review-bar-component" data-testid="review_bar_component">
      <div
        class="review-bar-content d-flex gl-justify-content-end"
        data-qa-selector="review_bar_content"
      >
        <preview-dropdown />
        <publish-button class="gl-ml-3" show-count />
      </div>
    </nav>
  </div>
</template>
