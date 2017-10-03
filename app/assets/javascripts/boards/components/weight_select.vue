<script>
/* global BoardService */

import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import eventHub from '../eventhub';

export default {
  props: {
    board: {
      type: Object,
      required: true,
    },
    value: {
      type: [Number, String],
      required: false,
    },
    defaultText: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    weights: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      isOpen: false,
    };
  },
  components: {
    loadingIcon,
  },
  computed: {
    weight() {
      if (parseInt(this.board.weight, 10) === 0) {
        return 'No Weight';
      }
      return this.board.weight || 'Any weight';
    },
  },
  methods: {
    selectWeight(weight) {
      this.$set(this.board, 'weight', weight);
      this.close();
    },
    open() {
      this.isOpen = true;
    },
    close() {
      this.isOpen = false;
    },
    toggle() {
      this.isOpen = !this.isOpen;
    },
  },
};
</script>

<template>
  <div class="dropdown weight" :class="{ open: isOpen }">
    <div class="title append-bottom-10">
      {{ title }}
      <a
        v-if="canEdit"
        class="edit-link pull-right"
        href="#"
        @click.prevent="toggle"
      >
        Edit
      </a>
    </div>
    <div
      class="dropdown-menu dropdown-menu-wide"
    >
      <ul
        ref="list"
      >
        <li>
          <a
            href="#"
            @click.prevent.stop="selectWeight(null)"
          >
            <i
              class="fa fa-check"
              v-if="!value"></i>
            Any weight
          </a>
        </li>
        <li
          v-for="weight in weights"
          :key="weight.id"
        >
          <a
            href="#"
            @click.prevent.stop="selectWeight(weight)">
            <i
              class="fa fa-check"
              v-if="weight === value"
            />
            {{ weight }}
          </a>
        </li>
      </ul>
    </div>
    <div class="value">
      {{ weight }}
    </div>
  </div>
</template>