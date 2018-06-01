<script>
import _ from 'underscore';
import LoadingIcon from '../../../vue_shared/components/loading_icon.vue';
import Item from './item.vue';

export default {
  components: {
    LoadingIcon,
    Item,
  },
  props: {
    isLoading: {
      type: Boolean,
      required: true,
    },
    items: {
      type: Array,
      required: true,
    },
    currentId: {
      type: String,
      required: true,
    },
    emptyText: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      search: '',
    };
  },
  computed: {
    hasMergeRequests() {
      return this.items.length !== 0;
    },
    hasNoSearchResults() {
      return this.search !== '' && !this.hasMergeRequests;
    },
  },
  watch: {
    isLoading() {
      this.focusSearch();
    },
  },
  methods: {
    viewMergeRequest(item) {
      this.$router.push(`/project/${item.projectPathWithNamespace}/merge_requests/${item.iid}`);
    },
    searchMergeRequests: _.debounce(function debounceSearch() {
      this.$emit('search', this.search);
    }, 250),
    focusSearch() {
      if (!this.isLoading) {
        this.$nextTick(() => {
          this.$refs.searchInput.focus();
        });
      }
    },
  },
};
</script>

<template>
  <div>
    <loading-icon
      class="mt-3 mb-3"
      v-if="isLoading"
      size="2"
    />
    <template v-else>
      <div class="dropdown-input mt-3 pb-3 mb-3 border-bottom">
        <input
          type="search"
          class="dropdown-input-field"
          placeholder="Search merge requests"
          v-model="search"
          @input="searchMergeRequests"
          ref="searchInput"
        />
        <i
          aria-hidden="true"
          class="fa fa-search dropdown-input-search"
        ></i>
      </div>
      <div class="dropdown-content ide-merge-requests-dropdown-content">
        <ul class="mb-3">
          <template v-if="hasMergeRequests">
            <li
              v-for="item in items"
              :key="item.id"
            >
              <item
                :item="item"
                :current-id="currentId"
                @click="viewMergeRequest"
              />
            </li>
          </template>
          <li
            v-else
            class="ide-merge-requests-empty d-flex align-items-center justify-content-center"
          >
            <template v-if="hasNoSearchResults">
              No merge requests found
            </template>
            <template v-else>
              {{ emptyText }}
            </template>
          </li>
        </ul>
      </div>
    </template>
  </div>
</template>

<style scoped>
.ide-merge-requests-empty {
  height: 230px;
}

.ide-merge-requests-dropdown-content {
  min-height: 230px;
  max-height: 470px;
}
</style>
