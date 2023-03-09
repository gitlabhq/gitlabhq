<script>
import * as Sentry from '@sentry/browser';
import { truncateNamespace } from '~/lib/utils/text_utility';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import AccessorUtilities from '~/lib/utils/accessor';
import { getTopFrequentItems } from '../utils';
import NavItem from './nav_item.vue';

export default {
  components: {
    ProjectAvatar,
    NavItem,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    storageKey: {
      type: String,
      required: true,
    },
    maxItems: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      cachedFrequentItems: [],
    };
  },
  computed: {
    remappedItems() {
      return this.cachedFrequentItems.map((item) => {
        const { id, name: title, avatarUrl: avatar, webUrl: link } = item;
        return {
          id,
          title,
          subtitle: truncateNamespace(item.namespace),
          avatar,
          link,
        };
      });
    },
  },
  created() {
    this.getItemsFromLocalStorage();
  },
  methods: {
    getItemsFromLocalStorage() {
      if (!AccessorUtilities.canUseLocalStorage()) {
        return;
      }
      try {
        const parsedCachedFrequentItems = JSON.parse(localStorage.getItem(this.storageKey));
        this.cachedFrequentItems = getTopFrequentItems(parsedCachedFrequentItems, this.maxItems);
      } catch (e) {
        Sentry.captureException(e);
      }
    },
  },
};
</script>

<template>
  <li class="gl-border-t gl-border-gray-50 gl-mx-3 gl-py-3">
    <div
      data-testid="list-title"
      aria-hidden="true"
      class="gl-text-gray-500 gl-font-weight-bold gl-font-xs gl-line-height-12 gl-letter-spacing-06em gl-my-3"
    >
      {{ title }}
    </div>
    <div
      v-if="!remappedItems.length"
      data-testid="empty-text"
      class="gl-text-gray-500 gl-font-sm gl-my-3"
    >
      <slot name="empty"></slot>
    </div>
    <ul :aria-label="title" class="gl-p-0 gl-list-style-none">
      <nav-item
        v-for="item in remappedItems"
        :key="item.title"
        :item="item"
        :link-classes="{ 'gl-py-2!': true }"
      >
        <template #icon>
          <project-avatar
            :project-id="item.id"
            :project-name="item.title"
            :project-avatar-url="item.avatar"
            :size="24"
            aria-hidden="true"
          />
        </template>
      </nav-item>
      <slot name="view-all-items"></slot>
    </ul>
  </li>
</template>
