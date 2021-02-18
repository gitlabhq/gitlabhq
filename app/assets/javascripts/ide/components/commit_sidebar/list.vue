<script>
import { GlModal, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { mapActions } from 'vuex';
import { __, sprintf } from '~/locale';
import ListItem from './list_item.vue';

export default {
  components: {
    GlIcon,
    ListItem,
    GlModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    fileList: {
      type: Array,
      required: true,
    },
    stagedList: {
      type: Boolean,
      required: false,
      default: false,
    },
    activeFileKey: {
      type: String,
      required: false,
      default: null,
    },
    keyPrefix: {
      type: String,
      required: true,
    },
    emptyStateText: {
      type: String,
      required: false,
      default: __('No changes'),
    },
  },
  computed: {
    titleText() {
      if (!this.title) return __('Changes');

      return sprintf(__('%{title} changes'), { title: this.title });
    },
    filesLength() {
      return this.fileList.length;
    },
  },
  methods: {
    ...mapActions(['unstageAllChanges', 'discardAllChanges']),
    openDiscardModal() {
      this.$refs.discardAllModal.show();
    },
    unstageAndDiscardAllChanges() {
      this.unstageAllChanges();
      this.discardAllChanges();
    },
  },
  discardModalText: __(
    "You will lose all uncommitted changes you've made in this project. This action cannot be undone.",
  ),
};
</script>

<template>
  <div class="ide-commit-list-container">
    <header class="multi-file-commit-panel-header d-flex mb-0">
      <div class="d-flex align-items-center flex-fill">
        <strong> {{ titleText }} </strong>
        <div class="d-flex ml-auto">
          <button
            v-if="!stagedList"
            v-gl-tooltip
            :title="__('Discard all changes')"
            :aria-label="__('Discard all changes')"
            :disabled="!filesLength"
            :class="{
              'disabled-content': !filesLength,
            }"
            type="button"
            class="d-flex ide-staged-action-btn p-0 border-0 align-items-center"
            data-placement="bottom"
            data-container="body"
            data-boundary="viewport"
            @click="openDiscardModal"
          >
            <gl-icon :size="16" name="remove-all" class="ml-auto mr-auto position-top-0" />
          </button>
        </div>
      </div>
    </header>
    <ul v-if="filesLength" class="multi-file-commit-list list-unstyled gl-mb-0">
      <li v-for="file in fileList" :key="file.key">
        <list-item
          :file="file"
          :key-prefix="keyPrefix"
          :staged-list="stagedList"
          :active-file-key="activeFileKey"
        />
      </li>
    </ul>
    <p v-else class="multi-file-commit-list form-text text-muted text-center">
      {{ emptyStateText }}
    </p>
    <gl-modal
      v-if="!stagedList"
      ref="discardAllModal"
      ok-variant="danger"
      modal-id="discard-all-changes"
      :ok-title="__('Discard all changes')"
      :title="__('Discard all changes?')"
      @ok="unstageAndDiscardAllChanges"
    >
      {{ $options.discardModalText }}
    </gl-modal>
  </div>
</template>
