<template>
  <div class="dropdown" :class="{ open: isOpen }">
    <div class="media">
      <label class="label-light media-body">{{ title }}</label>
      <a
        v-if="canEdit"
        class="edit-link"
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
            @click.prevent.stop="selectWeight(0)"
          >
            <i
              class="fa fa-check"
              v-if="0 === value"></i>
            No weight
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
              v-if="weight === value"></i>
            {{ weight }}
          </a>
        </li>
      </ul>
    </div>
    <div>
      {{ weight }}
    </div>
  </div>
</template>

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
      type: Number,
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
  },
  components: {
    loadingIcon,
  },
  computed: {
    weight() {
      if (parseInt(this.board.weight, 10) === 0) {
        return 'No weight';
      }
      return this.board.weight || 'Any weight';
    },
  },
  data() {
    return {
      isOpen: false,
      // TODO: use Issue.weight_options from backend
      weights: [1, 2, 3, 4, 5, 6, 7, 8, 9],
    };
  },
  methods: {
    selectWeight(weight) {
      this.$set(this.board, 'weight', weight);
      // this.$emit('input', weight);
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
