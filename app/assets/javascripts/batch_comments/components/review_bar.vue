<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters } from 'vuex';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { SET_REVIEW_BAR_RENDERED } from '~/batch_comments/stores/modules/batch_comments/mutation_types';
import { REVIEW_BAR_VISIBLE_CLASS_NAME } from '../constants';
import PreviewDropdown from './preview_dropdown.vue';
import SubmitDropdown from './submit_dropdown.vue';

export default {
  components: {
    PreviewDropdown,
    SubmitDropdown,
  },
  mixins: [glFeatureFlagMixin()],
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
    this.$store.commit(`batchComments/${SET_REVIEW_BAR_RENDERED}`);
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
    <nav class="review-bar-component js-review-bar" data-testid="review_bar_component">
      <div
        class="review-bar-content gl-flex gl-justify-content-end"
        data-testid="review-bar-content"
      >
        <preview-dropdown />
        <submit-dropdown />
      </div>
    </nav>
  </div>
</template>
