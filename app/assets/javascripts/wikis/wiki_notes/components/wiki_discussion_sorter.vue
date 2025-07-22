<script>
import {
  GlIcon,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import { WIKI_NOTES_SORT_ORDER, WIKI_SORT_ORDER_STORAGE_KEY } from '~/wikis/constants';
import { __ } from '~/locale';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import sortWikiDiscussion from '../../graphql/notes/sort_wiki_discussion.mutation.graphql';
import wikiDiscussionSortOrder from '../../graphql/notes/wiki_discussion_sort_order.query.graphql';

const SORT_OPTIONS = [
  { key: WIKI_NOTES_SORT_ORDER.CREATED_DESC, text: __('Newest first') },
  { key: WIKI_NOTES_SORT_ORDER.CREATED_ASC, text: __('Oldest first') },
];

export default {
  name: 'WikiDiscussionSorter',
  SORT_OPTIONS,
  WIKI_SORT_ORDER_STORAGE_KEY,
  components: {
    LocalStorageSync,
    GlIcon,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
  },
  data() {
    return {
      isLoading: false,
      wikiDiscussionSortOrder: null,
    };
  },
  apollo: {
    wikiDiscussionSortOrder,
  },
  computed: {
    dropdownLabel() {
      if (!this.wikiDiscussionSortOrder) return __('Sort by');
      return SORT_OPTIONS.find((o) => o.key === this.wikiDiscussionSortOrder).text;
    },
  },
  methods: {
    isSortDropdownItemActive(key) {
      return this.wikiDiscussionSortOrder === key;
    },
    updateSortOrder(key) {
      this.isLoading = true;
      try {
        this.$apollo.mutate({
          mutation: sortWikiDiscussion,
          variables: {
            sortOrder: key,
          },
        });
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<template>
  <div>
    <local-storage-sync
      :value="wikiDiscussionSortOrder"
      :storage-key="$options.WIKI_SORT_ORDER_STORAGE_KEY"
      :persist="true"
      as-string
    />
    <gl-disclosure-dropdown
      id="discussion-sort-dropdown"
      class="full-width-mobile"
      data-testid="discussion-sort-dropdown"
      :toggle-text="dropdownLabel"
      :disabled="isLoading"
      size="small"
      placement="bottom-end"
    >
      <gl-disclosure-dropdown-group id="discussion-sort">
        <gl-disclosure-dropdown-item
          v-for="{ text, key } in $options.SORT_OPTIONS"
          :key="text"
          :is-selected="isSortDropdownItemActive(key)"
          @action="updateSortOrder(key)"
        >
          <template #list-item>
            <gl-icon
              name="mobile-issue-close"
              data-testid="dropdown-item-checkbox"
              :class="[
                'gl-new-dropdown-item-check-icon',
                { 'gl-invisible': !isSortDropdownItemActive(key) },
              ]"
            />
            {{ text }}
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>
    </gl-disclosure-dropdown>
  </div>
</template>
