<script>
/* eslint-disable vue/require-default-prop, vue/require-prop-types */
import Identicon from '../../vue_shared/components/identicon.vue';

export default {
  components: {
    Identicon,
  },
  props: {
    matcher: {
      type: String,
      required: false,
    },
    itemId: {
      type: Number,
      required: true,
    },
    itemName: {
      type: String,
      required: true,
    },
    namespace: {
      type: String,
      required: false,
    },
    webUrl: {
      type: String,
      required: true,
    },
    avatarUrl: {
      required: true,
      validator(value) {
        return value === null || typeof value === 'string';
      },
    },
  },
  computed: {
    hasAvatar() {
      return this.avatarUrl !== null;
    },
    highlightedItemName() {
      if (this.matcher) {
        const matcherRegEx = new RegExp(this.matcher, 'gi');
        const matches = this.itemName.match(matcherRegEx);

        if (matches && matches.length > 0) {
          return this.itemName.replace(matches[0], `<b>${matches[0]}</b>`);
        }
      }
      return this.itemName;
    },
    /**
     * Smartly truncates item namespace by doing two things;
     * 1. Only include Group names in path by removing item name
     * 2. Only include first and last group names in the path
     *    when namespace has more than 2 groups present
     *
     * First part (removal of item name from namespace) can be
     * done from backend but doing so involves migration of
     * existing item namespaces which is not wise thing to do.
     */
    truncatedNamespace() {
      if (!this.namespace) {
        return null;
      }
      const namespaceArr = this.namespace.split(' / ');

      namespaceArr.splice(-1, 1);
      let namespace = namespaceArr.join(' / ');

      if (namespaceArr.length > 2) {
        namespace = `${namespaceArr[0]} / ... / ${namespaceArr.pop()}`;
      }

      return namespace;
    },
  },
};
</script>

<template>
  <li class="frequent-items-list-item-container">
    <a
      :href="webUrl"
      class="clearfix"
    >
      <div class="frequent-items-item-avatar-container">
        <img
          v-if="hasAvatar"
          :src="avatarUrl"
          class="avatar s32"
        />
        <identicon
          v-else
          :entity-id="itemId"
          :entity-name="itemName"
          size-class="s32"
        />
      </div>
      <div class="frequent-items-item-metadata-container">
        <div
          :title="itemName"
          class="frequent-items-item-title"
          v-html="highlightedItemName"
        >
        </div>
        <div
          v-if="truncatedNamespace"
          :title="namespace"
          class="frequent-items-item-namespace"
        >
          {{ truncatedNamespace }}
        </div>
      </div>
    </a>
  </li>
</template>
