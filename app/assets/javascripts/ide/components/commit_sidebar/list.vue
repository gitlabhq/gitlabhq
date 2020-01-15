<script>
import $ from 'jquery';
import { mapActions } from 'vuex';
import { __, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import DeprecatedModal2 from '~/vue_shared/components/deprecated_modal_2.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import ListItem from './list_item.vue';

export default {
  components: {
    Icon,
    ListItem,
    GlModal: DeprecatedModal2,
  },
  directives: {
    tooltip,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    fileList: {
      type: Array,
      required: true,
    },
    iconName: {
      type: String,
      required: true,
    },
    action: {
      type: String,
      required: true,
    },
    actionBtnText: {
      type: String,
      required: true,
    },
    actionBtnIcon: {
      type: String,
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
      return sprintf(__('%{title} changes'), {
        title: this.title,
      });
    },
    filesLength() {
      return this.fileList.length;
    },
  },
  methods: {
    ...mapActions(['stageAllChanges', 'unstageAllChanges', 'discardAllChanges']),
    actionBtnClicked() {
      this[this.action]();

      $(this.$refs.actionBtn).tooltip('hide');
    },
    openDiscardModal() {
      $('#discard-all-changes').modal('show');
    },
  },
  discardModalText: __(
    "You will lose all the unstaged changes you've made in this project. This action cannot be undone.",
  ),
};
</script>

<template>
  <div class="ide-commit-list-container">
    <header class="multi-file-commit-panel-header d-flex mb-0">
      <div class="d-flex align-items-center flex-fill">
        <icon v-once :name="iconName" :size="18" class="append-right-8" />
        <strong> {{ titleText }} </strong>
        <div class="d-flex ml-auto">
          <button
            ref="actionBtn"
            v-tooltip
            :title="actionBtnText"
            :aria-label="actionBtnText"
            :disabled="!filesLength"
            :class="{
              'disabled-content': !filesLength,
            }"
            type="button"
            class="d-flex ide-staged-action-btn p-0 border-0 align-items-center"
            data-placement="bottom"
            data-container="body"
            data-boundary="viewport"
            @click="actionBtnClicked"
          >
            <icon :name="actionBtnIcon" :size="16" class="ml-auto mr-auto" />
          </button>
          <button
            v-if="!stagedList"
            v-tooltip
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
            <icon :size="16" name="remove-all" class="ml-auto mr-auto" />
          </button>
        </div>
      </div>
    </header>
    <ul v-if="filesLength" class="multi-file-commit-list list-unstyled append-bottom-0">
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
      id="discard-all-changes"
      :footer-primary-button-text="__('Discard all changes')"
      :header-title-text="__('Discard all unstaged changes?')"
      footer-primary-button-variant="danger"
      @submit="discardAllChanges"
    >
      {{ $options.discardModalText }}
    </gl-modal>
  </div>
</template>
