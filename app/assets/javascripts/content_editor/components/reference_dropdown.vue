<script>
import { GlDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlDropdownItem,
  },

  props: {
    char: {
      type: String,
      required: true,
    },

    referenceProps: {
      type: Object,
      required: true,
    },

    items: {
      type: Array,
      required: true,
    },

    command: {
      type: Function,
      required: true,
    },
  },

  data() {
    return {
      selectedIndex: 0,
    };
  },

  computed: {
    isUser() {
      return this.referenceProps.referenceType === 'user';
    },

    isIssue() {
      return this.referenceProps.referenceType === 'issue';
    },

    isMergeRequest() {
      return this.referenceProps.referenceType === 'merge_request';
    },

    isMilestone() {
      return this.referenceProps.referenceType === 'milestone';
    },
  },

  watch: {
    items() {
      this.selectedIndex = 0;
    },
  },

  methods: {
    getReferenceText(item) {
      switch (this.referenceProps.referenceType) {
        case 'user':
          return `${this.char}${item.username}`;
        case 'issue':
        case 'merge_request':
          return `${this.char}${item.iid}`;
        case 'milestone':
          return `${this.char}${item.title}`;
        default:
          return '';
      }
    },

    onKeyDown({ event }) {
      if (event.key === 'ArrowUp') {
        this.upHandler();
        return true;
      }

      if (event.key === 'ArrowDown') {
        this.downHandler();
        return true;
      }

      if (event.key === 'Enter') {
        this.enterHandler();
        return true;
      }

      return false;
    },

    upHandler() {
      this.selectedIndex = (this.selectedIndex + this.items.length - 1) % this.items.length;
    },

    downHandler() {
      this.selectedIndex = (this.selectedIndex + 1) % this.items.length;
    },

    enterHandler() {
      this.selectItem(this.selectedIndex);
    },

    selectItem(index) {
      const item = this.items[index];

      if (item) {
        this.command({
          text: this.getReferenceText(item),
          href: '#',
          ...this.referenceProps,
        });
      }
    },
  },
};
</script>

<template>
  <ul
    :class="{ show: items.length > 0 }"
    class="gl-new-dropdown dropdown-men"
    data-testid="content-editor-reference-dropdown"
  >
    <div class="gl-new-dropdown-inner gl-overflow-y-auto">
      <gl-dropdown-item
        v-for="(item, index) in items"
        :key="index"
        :class="{ 'gl-bg-gray-50': index === selectedIndex }"
        @click="selectItem(index)"
      >
        <span v-if="isUser">
          {{ item.username }}
          <small>{{ item.name }}</small>
        </span>
        <span v-if="isIssue || isMergeRequest || isMilestone">
          <small>{{ item.iid }}</small>
          {{ item.title }}
        </span>
      </gl-dropdown-item>
    </div>
  </ul>
</template>
