<template>
  <div class="dropdown milestone" :class="{ open: isOpen }">
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
          class="dropdown-menu-item"
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
    <div class="value">
      {{ milestoneTitle }}
    </div>
  </div>
</template>

<script>
/* global BoardService */

import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import extraMilestones from '../mixins/extra_milestones';

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
  data() {
    return {
      isOpen: false,
      loading: true,
      milestones: [],
      extraMilestones,
    };
  },
  components: {
    loadingIcon,
  },
  computed: {
    milestoneTitle() {
      return this.board.milestone ? this.board.milestone.title : this.defaultText;
    },
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
  },
};
</script>
