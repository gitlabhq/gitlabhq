<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import ListItem from './list_item.vue';
import ListCollapsed from './list_collapsed.vue';
import { __, sprintf } from '~/locale';

export default {
  components: {
    Icon,
    ListItem,
    ListCollapsed,
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
    showToggle: {
      type: Boolean,
      required: false,
      default: true,
    },
    icon: {
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
    itemActionComponent: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['rightPanelCollapsed']),
    ...mapGetters(['collapseButtonIcon', 'collapseButtonTooltip']),
    titleText() {
      return sprintf(__('%{title} changes'), {
        title: this.title,
      });
    },
  },
  methods: {
    ...mapActions(['toggleRightPanelCollapsed', 'stageAllChanges', 'unstageAllChanges']),
    actionBtnClicked() {
      this[this.action]();
    },
  },
};
</script>

<template>
  <div
    class="ide-commit-list-container"
    :class="{
      'is-collapsed': rightPanelCollapsed,
    }"
  >
    <header
      class="multi-file-commit-panel-header"
      :class="{
        'is-collapsed': rightPanelCollapsed,
      }"
    >
      <div
        v-if="!rightPanelCollapsed"
        class="multi-file-commit-panel-header-title"
        :class="{
          'append-right-10': showToggle,
        }"
      >
        <icon
          v-once
          :name="icon"
          :size="18"
        />
        {{ titleText }}
        <button
          type="button"
          class="btn btn-blank btn-link ide-staged-action-btn"
          @click="actionBtnClicked"
        >
          {{ actionBtnText }}
        </button>
      </div>
      <button
        v-if="showToggle"
        v-tooltip
        :title="collapseButtonTooltip"
        data-container="body"
        data-placement="left"
        type="button"
        class="btn btn-transparent multi-file-commit-panel-collapse-btn"
        :aria-label="__('Toggle sidebar')"
        @click.stop="toggleRightPanelCollapsed"
      >
        <icon
          :name="collapseButtonIcon"
          :size="18"
        />
      </button>
    </header>
    <list-collapsed
      v-if="rightPanelCollapsed"
      :files="fileList"
      :icon="icon"
      :title="title"
    />
    <template v-else>
      <ul
        v-if="fileList.length"
        class="multi-file-commit-list list-unstyled append-bottom-0"
      >
        <li
          v-for="file in fileList"
          :key="file.key"
        >
          <list-item
            :file="file"
            :action-component="itemActionComponent"
            :key-prefix="title"
          />
        </li>
      </ul>
      <p
        v-else
        class="multi-file-commit-list help-block"
      >
        {{ __('No changes') }}
      </p>
    </template>
  </div>
</template>
