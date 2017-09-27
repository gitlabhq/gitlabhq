<template>
  <div class="dropdown" :class="{ open: isOpen }">
    <div
      class="dropdown-menu dropdown-menu-wide"
    >
      <div class="dropdown-input">
        <input
          ref="search"
          class="dropdown-input-field"
          type="search"
          placeholder="Search milestones">
        <i aria-hidden="true" data-hidden="true" class="fa fa-search dropdown-input-search"></i>
      </div>
      <ul
        ref="list"
      >
        <li
          v-for="milestone in extraMilestones"
          :key="milestone.id"
        >
          <a
            href="#"
            @click.prevent.stop="selectMilestone(milestone)">
            <i
              class="fa fa-check"
              v-if="milestone.id === value"></i>
            {{ milestone.title }}
          </a>
        </li>
        <li class="divider"></li>
        <li v-if="loading">
          <loading-icon />
        </li>
        <li
          v-else
          v-for="milestone in milestones"
          :key="milestone.id"
        >
          <a
            href="#"
            @click.prevent.stop="selectMilestone(milestone)">
            <i
              class="fa fa-check"
              v-if="milestone.id === value"></i>
            {{ milestone.title }}
          </a>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
/* global BoardService */

import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import extraMilestones from '../mixins/extra_milestones';
import eventHub from '../eventhub';

export default {
  props: {
    board: {
      type: Object,
      required: true,
    },
    milestonePath: {
      type: String,
      required: true,
    },
    value: {
      type: Number,
      required: false,
    },
  },
  components: {
    loadingIcon,
  },
  data() {
    return {
      isOpen: false,
      loading: true,
      milestones: [],
      extraMilestones,
    };
  },
  mounted() {
    this.$http.get(this.milestonePath)
      .then(resp => resp.json())
      .then((data) => {
        this.milestones = data;
        this.loading = false;
      })
      .catch(() => {
        this.loading = false;
      });
    eventHub.$on('open', this.open);
    eventHub.$on('close', this.close);
    eventHub.$on('toggle', this.toggle);
    this.$nextTick(() => {
      this.$refs.search.focus();
    });
  },
  beforeDestroy() {
    eventHub.$off('open', this.open);
    eventHub.$off('close', this.close);
    eventHub.$off('toggle', this.toggle);
  },
  methods: {
    selectMilestone(milestone) {
      this.$set(this.board, 'milestone', milestone);
      this.$emit('input', milestone.id);
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
