<script>
import { mapActions, mapGetters } from 'vuex';
import { REVIEW_BAR_VISIBLE_CLASS_NAME } from '../constants';
import PreviewDropdown from './preview_dropdown.vue';
import PublishButton from './publish_button.vue';

export default {
  components: {
    PreviewDropdown,
    PublishButton,
  },
  computed: {
    ...mapGetters(['isNotesFetched']),
  },
  watch: {
    isNotesFetched() {
      if (this.isNotesFetched) {
        this.expandAllDiscussions();
      }
    },
  },
  mounted() {
    document.body.classList.add(REVIEW_BAR_VISIBLE_CLASS_NAME);
  },
  beforeDestroy() {
    document.body.classList.remove(REVIEW_BAR_VISIBLE_CLASS_NAME);
  },
  methods: {
    ...mapActions('batchComments', ['expandAllDiscussions']),
  },
};
</script>
<template>
  <div>
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
