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
        {{ titleText }}
        <div class="d-flex ml-auto">
          <button
            v-tooltip
            v-show="filesLength"
            :class="{
              'd-flex': filesLength
            }"
            :title="actionBtnText"
            type="button"
            class="btn btn-default ide-staged-action-btn p-0 order-1 align-items-center"
            data-placement="bottom"
            data-container="body"
            data-boundary="viewport"
            @click="actionBtnClicked"
          >
            <icon
              :name="actionBtnIcon"
              :size="12"
              class="ml-auto mr-auto"
            />
          </button>
          <span
            :class="{
              'rounded-right': !filesLength
            }"
            class="ide-commit-file-count order-0 rounded-left text-center"
          >
            {{ filesLength }}
          </span>
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
      class="multi-file-commit-list form-text text-muted"
    >
      {{ __('No changes') }}
    </p>
  </div>
</template>
