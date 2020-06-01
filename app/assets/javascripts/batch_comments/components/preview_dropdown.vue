<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import { sprintf, n__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import DraftsCount from './drafts_count.vue';
import PublishButton from './publish_button.vue';
import PreviewItem from './preview_item.vue';

export default {
  components: {
    GlLoadingIcon,
    Icon,
    DraftsCount,
    PublishButton,
    PreviewItem,
  },
  computed: {
    ...mapGetters(['isNotesFetched']),
    ...mapGetters('batchComments', ['draftsCount', 'sortedDrafts']),
    ...mapState('batchComments', ['showPreviewDropdown']),
    dropdownTitle() {
      return sprintf(
        n__('%{count} pending comment', '%{count} pending comments', this.draftsCount),
        { count: this.draftsCount },
      );
    },
  },
  watch: {
    showPreviewDropdown() {
      if (this.showPreviewDropdown && this.$refs.dropdown) {
        this.$nextTick(() => this.$refs.dropdown.focus());
      }
    },
  },
  mounted() {
    document.addEventListener('click', this.onClickDocument);
  },
  beforeDestroy() {
    document.removeEventListener('click', this.onClickDocument);
  },
  methods: {
    ...mapActions('batchComments', ['toggleReviewDropdown']),
    isLast(index) {
      return index === this.sortedDrafts.length - 1;
    },
    onClickDocument({ target }) {
      if (
        this.showPreviewDropdown &&
        !target.closest('.review-preview-dropdown, .js-publish-draft-button')
      ) {
        this.toggleReviewDropdown();
      }
    },
  },
};
</script>

<template>
  <div
    class="dropdown float-right review-preview-dropdown"
    :class="{
      show: showPreviewDropdown,
    }"
  >
    <button
      ref="dropdown"
      type="button"
      class="btn btn-success review-preview-dropdown-toggle qa-review-preview-toggle"
      @click="toggleReviewDropdown"
    >
      {{ __('Finish review') }}
      <drafts-count />
      <icon name="angle-up" />
    </button>
    <div
      class="dropdown-menu dropdown-menu-large dropdown-menu-right dropdown-open-top"
      :class="{
        show: showPreviewDropdown,
      }"
    >
      <div class="dropdown-title">
        {{ dropdownTitle }}
        <button
          :aria-label="__('Close')"
          type="button"
          class="dropdown-title-button dropdown-menu-close"
          @click="toggleReviewDropdown"
        >
          <icon name="close" />
        </button>
      </div>
      <div class="dropdown-content">
        <ul v-if="isNotesFetched">
          <li v-for="(draft, index) in sortedDrafts" :key="draft.id">
            <preview-item :draft="draft" :is-last="isLast(index)" />
          </li>
        </ul>
        <gl-loading-icon v-else size="lg" class="prepend-top-default append-bottom-default" />
      </div>
      <div class="dropdown-footer">
        <publish-button
          :show-count="false"
          :should-publish="true"
          :label="__('Submit review')"
          class="float-right gl-mr-3"
        />
      </div>
    </div>
  </div>
</template>
