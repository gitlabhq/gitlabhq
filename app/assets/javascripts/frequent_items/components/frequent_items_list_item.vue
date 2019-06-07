<script>
/* eslint-disable vue/require-default-prop */
import _ from 'underscore';
import Identicon from '~/vue_shared/components/identicon.vue';
import highlight from '~/lib/utils/highlight';
import { truncateNamespace } from '~/lib/utils/text_utility';

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
      return _.isString(this.avatarUrl) && !_.isEmpty(this.avatarUrl);
    },
    truncatedNamespace() {
      return truncateNamespace(this.namespace);
    },
    highlightedItemName() {
      return highlight(this.itemName, this.matcher);
    },
  },
};
</script>

<template>
  <li class="frequent-items-list-item-container">
    <a :href="webUrl" class="clearfix">
      <div class="frequent-items-item-avatar-container">
        <img v-if="hasAvatar" :src="avatarUrl" class="avatar rect-avatar s32" />
        <identicon
          v-else
          :entity-id="itemId"
          :entity-name="itemName"
          size-class="s32"
          class="rect-avatar"
        />
      </div>
      <div class="frequent-items-item-metadata-container">
        <div
          :title="itemName"
          class="frequent-items-item-title js-frequent-items-item-title"
          v-html="highlightedItemName"
        ></div>
        <div
          v-if="namespace"
          :title="namespace"
          class="frequent-items-item-namespace js-frequent-items-item-namespace"
        >
          {{ truncatedNamespace }}
        </div>
      </div>
    </a>
  </li>
</template>
