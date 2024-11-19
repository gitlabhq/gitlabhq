<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlModal, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import { __ } from '~/locale';
import ListItem from './list_item.vue';

export default {
  components: {
    GlButton,
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
  modal: {
    actionPrimary: {
      text: __('Discard all changes'),
      attributes: {
        variant: 'danger',
      },
    },
    actionCancel: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
    },
  },
  computed: {
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
    <header class="multi-file-commit-panel-header gl-mb-0 gl-flex">
      <div class="flex-fill gl-flex gl-items-center">
        <strong> {{ __('Changes') }} </strong>
        <div class="gl-ml-auto gl-flex">
          <gl-button
            v-if="!stagedList"
            v-gl-tooltip
            :title="__('Discard all changes')"
            :aria-label="__('Discard all changes')"
            :disabled="!filesLength"
            :class="{
              'disabled-content': !filesLength,
            }"
            class="!gl-shadow-none"
            category="tertiary"
            icon="remove"
            data-placement="bottom"
            data-container="body"
            data-boundary="viewport"
            @click="openDiscardModal"
          />
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
    <p v-else class="multi-file-commit-list form-text gl-text-center gl-text-subtle">
      {{ emptyStateText }}
    </p>
    <gl-modal
      v-if="!stagedList"
      ref="discardAllModal"
      modal-id="discard-all-changes"
      :title="__('Discard all changes?')"
      :action-primary="$options.modal.actionPrimary"
      :action-cancel="$options.modal.actionCancel"
      @primary="unstageAndDiscardAllChanges"
    >
      {{ $options.discardModalText }}
    </gl-modal>
  </div>
</template>
