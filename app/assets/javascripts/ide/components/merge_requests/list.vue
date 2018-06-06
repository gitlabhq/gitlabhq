<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import _ from 'underscore';
import LoadingIcon from '../../../vue_shared/components/loading_icon.vue';
import Item from './item.vue';

export default {
  components: {
    LoadingIcon,
    Item,
  },
  props: {
    type: {
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
    ...mapGetters('mergeRequests', ['getData']),
    ...mapState(['currentMergeRequestId', 'currentProjectId']),
    data() {
      return this.getData(this.type);
    },
    isLoading() {
      return this.data.isLoading;
    },
    mergeRequests() {
      return this.data.mergeRequests;
    },
    hasMergeRequests() {
      return this.mergeRequests.length !== 0;
    },
    hasNoSearchResults() {
      return this.search !== '' && !this.hasMergeRequests;
    },
  },
  watch: {
    isLoading: {
      handler: 'focusSearch',
    },
  },
  mounted() {
    this.loadMergeRequests();
  },
  methods: {
    ...mapActions('mergeRequests', ['fetchMergeRequests', 'openMergeRequest']),
    loadMergeRequests() {
      this.fetchMergeRequests({ type: this.type, search: this.search });
    },
    viewMergeRequest(item) {
      this.openMergeRequest({
        projectPath: item.projectPathWithNamespace,
        id: item.iid,
      });
    },
    searchMergeRequests: _.debounce(function debounceSearch() {
      this.loadMergeRequests();
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
    <div class="dropdown-input mt-3 pb-3 mb-0 border-bottom">
      <input
        type="search"
        class="dropdown-input-field"
        :placeholder="__('Search merge requests')"
        v-model="search"
        @input="searchMergeRequests"
        ref="searchInput"
      />
      <i
        aria-hidden="true"
        class="fa fa-search dropdown-input-search"
      ></i>
    </div>
    <div class="dropdown-content ide-merge-requests-dropdown-content d-flex">
      <loading-icon
        class="mt-3 mb-3 align-self-center ml-auto mr-auto"
        v-if="isLoading"
        size="2"
      />
      <ul
        v-else
        class="mb-3 w-100"
      >
        <template v-if="hasMergeRequests">
          <li
            v-for="item in mergeRequests"
            :key="item.id"
          >
            <item
              :item="item"
              :current-id="currentMergeRequestId"
              :current-project-id="currentProjectId"
              @click="viewMergeRequest"
            />
          </li>
        </template>
        <li
          v-else
          class="ide-merge-requests-empty d-flex align-items-center justify-content-center"
        >
          <template v-if="hasNoSearchResults">
            {{ __('No merge requests found') }}
          </template>
          <template v-else>
            {{ emptyText }}
          </template>
        </li>
      </ul>
    </div>
  </div>
</template>
