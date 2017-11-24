<script>
  import icon from '../../../vue_shared/components/icon.vue';
  import listItem from './list_item.vue';
  import listCollapsed from './list_collapsed.vue';

  export default {
    components: {
      icon,
      listItem,
      listCollapsed,
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
      collapsed: {
        type: Boolean,
        required: true,
      },
    },
    methods: {
      toggleCollapsed() {
        this.$emit('toggleCollapsed');
      },
    },
  };
</script>

<template>
  <div class="multi-file-commit-panel-section">
    <header
      class="multi-file-commit-panel-header"
      :class="{
        'is-collapsed': collapsed,
      }"
    >
      <icon
        name="list-bulleted"
        :size="18"
        css-classes="append-right-default"
      />
      <template v-if="!collapsed">
        {{ title }}
        <button
          type="button"
          class="btn btn-transparent multi-file-commit-panel-collapse-btn"
          @click="toggleCollapsed"
        >
          <i
            aria-hidden="true"
            class="fa fa-angle-double-right"
          >
          </i>
        </button>
      </template>
    </header>
    <div class="multi-file-commit-list">
      <list-collapsed
        v-if="collapsed"
      />
      <template v-else>
        <ul
          v-if="fileList.length"
          class="list-unstyled append-bottom-0"
        >
          <li
            v-for="file in fileList"
            :key="file.key"
          >
            <list-item
              :file="file"
            />
          </li>
        </ul>
        <div
          v-else
          class="help-block prepend-top-0"
        >
          No changes
        </div>
      </template>
    </div>
  </div>
</template>
