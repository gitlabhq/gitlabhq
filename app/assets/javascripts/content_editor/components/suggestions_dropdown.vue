<script>
import { GlAvatarLabeled, GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlAvatarLabeled,
    GlLoadingIcon,
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

    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  data() {
    return {
      selectedIndex: -1,
    };
  },

  computed: {
    isReference() {
      return this.nodeType.startsWith('reference');
    },

    isCommand() {
      return this.isReference && this.nodeProps.referenceType === 'command';
    },

    isUser() {
      return this.isReference && this.nodeProps.referenceType === 'user';
    },

    isIssue() {
      return this.isReference && this.nodeProps.referenceType === 'issue';
    },

    isLabel() {
      return this.isReference && this.nodeProps.referenceType === 'label';
    },

    isEpic() {
      return this.isReference && this.nodeProps.referenceType === 'epic';
    },

    isSnippet() {
      return this.isReference && this.nodeProps.referenceType === 'snippet';
    },

    isVulnerability() {
      return this.isReference && this.nodeProps.referenceType === 'vulnerability';
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
      this.selectedIndex = -1;
    },
    selectedIndex() {
      this.scrollIntoView();
    },
  },

  methods: {
    getText(item) {
      if (this.isEmoji) return item.e;

      switch (this.isReference && this.nodeProps.referenceType) {
        case 'user':
          return `${this.char}${item.username}`;
        case 'issue':
        case 'merge_request':
          return `${this.char}${item.iid}`;
        case 'snippet':
          return `${this.char}${item.id}`;
        case 'milestone':
          return `${this.char}${item.title}`;
        case 'label':
          return item.title;
        case 'command':
          return `${this.char}${item.name}`;
        case 'epic':
          return item.reference;
        case 'vulnerability':
          return `[vulnerability:${item.id}]`;
        default:
          return '';
      }
    },

    getProps(item) {
      const props = {};

      if (this.isEmoji) {
        Object.assign(props, {
          name: item.name,
          unicodeVersion: item.u,
          title: item.d,
          moji: item.e,
        });
      }

      if (this.isLabel || this.isMilestone) {
        Object.assign(props, {
          originalText: `${this.char}${
            /\W/.test(item.title) ? JSON.stringify(item.title) : item.title
          }`,
        });
      }

      if (this.isLabel) {
        Object.assign(props, {
          text: item.title,
          color: item.color,
        });
      }

      Object.assign(props, this.nodeProps);

      return props;
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

    scrollIntoView() {
      this.$refs.dropdownItems[this.selectedIndex]?.scrollIntoView({ block: 'nearest' });
    },

    selectItem(index) {
      const item = this.items[index];

      if (item) {
        this.command({
          text: this.getText(item),
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
  <div class="gl-new-dropdown content-editor-suggestions-dropdown">
    <div
      v-if="!loading && items.length > 0"
      class="gl-new-dropdown-panel gl-display-block! gl-absolute"
    >
      <div class="gl-new-dropdown-inner">
        <ul class="gl-new-dropdown-contents" data-testid="content-editor-suggestions-dropdown">
          <li
            v-for="(item, index) in items"
            :key="index"
            role="presentation"
            class="gl-new-dropdown-item"
            :class="{ focused: index === selectedIndex }"
          >
            <div
              ref="dropdownItems"
              type="button"
              role="menuitem"
              class="gl-new-dropdown-item-content"
              @click="selectItem(index)"
            >
              <div class="gl-new-dropdown-item-text-wrapper">
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
                <span v-if="isVulnerability || isSnippet">
                  <small>{{ item.id }}</small>
                  {{ item.title }}
                </span>
                <span v-if="isEpic">
                  <small>{{ item.reference }}</small>
                  {{ item.title }}
                </span>
                <span v-if="isMilestone">
                  {{ item.title }}
                </span>
                <span v-if="isLabel" class="gl-display-flex">
                  <span
                    data-testid="label-color-box"
                    class="dropdown-label-box gl-flex-shrink-0 gl-top-0 gl-mr-3"
                    :style="{ backgroundColor: item.color }"
                  ></span>
                  {{ item.title }}
                </span>
                <div v-if="isCommand">
                  <div class="gl-mb-1">
                    <span class="gl-font-weight-bold">/{{ item.name }}</span>
                    <em class="gl-text-gray-500 gl-font-sm">{{ item.params[0] }}</em>
                  </div>
                  <small class="gl-text-gray-500"> {{ item.description }} </small>
                </div>
                <div v-if="isEmoji" class="gl-display-flex gl-align-items-center">
                  <div class="gl-pr-4 gl-font-lg">{{ item.e }}</div>
                  <div class="gl-flex-grow-1">
                    {{ item.name }}<br />
                    <small>{{ item.d }}</small>
                  </div>
                </div>
              </div>
            </div>
          </li>
        </ul>
      </div>
    </div>
    <div v-if="loading" class="gl-new-dropdown-panel gl-display-block! gl-absolute">
      <div class="gl-new-dropdown-inner">
        <div class="gl-px-4 gl-py-3">
          <gl-loading-icon size="sm" class="gl-display-inline-block" /> {{ __('Loading...') }}
        </div>
      </div>
    </div>
  </div>
</template>
