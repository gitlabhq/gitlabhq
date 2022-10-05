<script>
import { GlDropdownItem, GlAvatarLabeled } from '@gitlab/ui';

export default {
  components: {
    GlDropdownItem,
    GlAvatarLabeled,
  },

  props: {
    char: {
      type: String,
      required: true,
    },

    nodeType: {
      type: String,
      required: true,
    },

    nodeProps: {
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
    isReference() {
      return this.nodeType === 'reference';
    },

    isUser() {
      return this.isReference && this.nodeProps.referenceType === 'user';
    },

    isIssue() {
      return this.isReference && this.nodeProps.referenceType === 'issue';
    },

    isMergeRequest() {
      return this.isReference && this.nodeProps.referenceType === 'merge_request';
    },

    isMilestone() {
      return this.isReference && this.nodeProps.referenceType === 'milestone';
    },

    isEmoji() {
      return this.nodeType === 'emoji';
    },
  },

  watch: {
    items() {
      this.selectedIndex = 0;
    },
  },

  methods: {
    getText(item) {
      if (this.isEmoji) return item.e;

      switch (this.nodeType === 'reference' && this.nodeProps.referenceType) {
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

    getProps(item) {
      if (this.isEmoji) {
        return {
          name: item.name,
          unicodeVersion: item.u,
          title: item.d,
          moji: item.e,
          ...this.nodeProps,
        };
      }

      return this.nodeProps;
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
          text: this.getText(item),
          href: '#',
          ...this.getProps(item),
        });
      }
    },

    avatarSubLabel(item) {
      return item.count ? `${item.name} (${item.count})` : item.name;
    },
  },
};
</script>

<template>
  <ul
    :class="{ show: items.length > 0 }"
    class="gl-new-dropdown dropdown-menu"
    data-testid="content-editor-suggestions-dropdown"
  >
    <div class="gl-new-dropdown-inner gl-overflow-y-auto">
      <gl-dropdown-item
        v-for="(item, index) in items"
        :key="index"
        :class="{ 'gl-bg-gray-50': index === selectedIndex }"
        @click="selectItem(index)"
      >
        <gl-avatar-labeled
          v-if="isUser"
          :label="item.username"
          :sub-label="avatarSubLabel(item)"
          :src="item.avatar_url"
          :entity-name="item.username"
          :shape="item.type === 'Group' ? 'rect' : 'circle'"
          :size="32"
        />
        <span v-if="isIssue || isMergeRequest">
          <small>{{ item.iid }}</small>
          {{ item.title }}
        </span>
        <span v-if="isMilestone">
          {{ item.title }}
        </span>
        <div v-if="isEmoji" class="gl-display-flex gl-flex gl-align-items-center">
          <div class="gl-pr-4 gl-font-lg">{{ item.e }}</div>
          <div class="gl-flex-grow-1">
            {{ item.name }}<br />
            <small>{{ item.d }}</small>
          </div>
        </div>
      </gl-dropdown-item>
    </div>
  </ul>
</template>
