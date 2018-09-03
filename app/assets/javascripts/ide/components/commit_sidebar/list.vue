<script>
import { mapActions } from 'vuex';
import { __, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import ListItem from './list_item.vue';

export default {
  components: {
    Icon,
    ListItem,
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
    itemActionComponent: {
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
    ...mapActions(['stageAllChanges', 'unstageAllChanges']),
    actionBtnClicked() {
      this[this.action]();
    },
  },
};
</script>

<template>
  <div
    class="ide-commit-list-container"
  >
    <header
      class="multi-file-commit-panel-header"
    >
      <div
        class="multi-file-commit-panel-header-title"
      >
        <icon
          v-once
          :name="iconName"
          :size="18"
        />
        <strong>
          {{ titleText }}
        </strong>
        <div class="d-flex ml-auto">
          <button
            v-tooltip
            :title="actionBtnText"
            :aria-label="actionBtnText"
            :disabled="!filesLength"
            :class="{
              'disabled-content': !filesLength
            }"
            type="button"
            class="d-flex ide-staged-action-btn p-0 border-0 align-items-center"
            data-placement="bottom"
            data-container="body"
            data-boundary="viewport"
            @click="actionBtnClicked"
          >
            <icon
              :name="actionBtnIcon"
              :size="16"
              class="mr-0"
            />
          </button>
        </div>
      </div>
    </header>
    <ul
      v-if="filesLength"
      class="multi-file-commit-list list-unstyled append-bottom-0"
    >
      <li
        v-for="file in fileList"
        :key="file.key"
      >
        <list-item
          :file="file"
          :action-component="itemActionComponent"
          :key-prefix="keyPrefix"
          :staged-list="stagedList"
          :active-file-key="activeFileKey"
        />
      </li>
    </ul>
    <p
      v-else
      class="multi-file-commit-list form-text text-muted text-center"
    >
      {{ emptyStateText }}
    </p>
  </div>
</template>
