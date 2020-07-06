<script>
import FunctionRow from './function_row.vue';
import ItemCaret from '~/groups/components/item_caret.vue';

export default {
  components: {
    ItemCaret,
    FunctionRow,
  },
  props: {
    env: {
      type: Array,
      required: true,
    },
    envName: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isOpen: true,
    };
  },
  computed: {
    envId() {
      if (this.envName === '*') {
        return 'env-global';
      }

      return `env-${this.envName}`;
    },
    isOpenClass() {
      return {
        'is-open': this.isOpen,
      };
    },
  },
  methods: {
    toggleOpen() {
      this.isOpen = !this.isOpen;
    },
  },
};
</script>

<template>
  <li :id="envId" :class="isOpenClass" class="group-row has-children">
    <div
      class="group-row-contents d-flex justify-content-end align-items-center py-2"
      role="button"
      @click.stop="toggleOpen"
    >
      <div class="folder-toggle-wrap d-flex align-items-center">
        <item-caret :is-group-open="isOpen" />
      </div>
      <div class="group-text flex-grow title namespace-title gl-ml-3">
        {{ envName }}
      </div>
    </div>
    <ul v-if="isOpen" class="content-list group-list-tree">
      <function-row v-for="(f, index) in env" :key="f.name" :index="index" :func="f" />
    </ul>
  </li>
</template>
