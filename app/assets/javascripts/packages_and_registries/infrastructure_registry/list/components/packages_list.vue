<script>
import { GlPagination } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import Tracking from '~/tracking';
import DeletePackageModal from '~/packages_and_registries/shared/components/delete_package_modal.vue';
import PackagesListRow from '~/packages_and_registries/infrastructure_registry/shared/package_list_row.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import { TRACKING_ACTIONS } from '~/packages_and_registries/shared/constants';
import { TRACK_CATEGORY } from '~/packages_and_registries/infrastructure_registry/shared/constants';

export default {
  components: {
    GlPagination,
    DeletePackageModal,
    PackagesListLoader,
    PackagesListRow,
  },
  mixins: [Tracking.mixin()],
  inject: {
    isGroupPage: {
      default: false,
    },
  },
  data() {
    return {
      itemToBeDeleted: null,
    };
  },
  computed: {
    ...mapState({
      perPage: (state) => state.pagination.perPage,
      totalItems: (state) => state.pagination.total,
      page: (state) => state.pagination.page,
      isLoading: 'isLoading',
    }),
    ...mapGetters({ list: 'getList' }),
    currentPage: {
      get() {
        return this.page;
      },
      set(value) {
        this.$emit('page:changed', value);
      },
    },
    isListEmpty() {
      return !this.list || this.list.length === 0;
    },
    tracking() {
      return {
        category: TRACK_CATEGORY,
      };
    },
  },
  methods: {
    setItemToBeDeleted(item) {
      this.itemToBeDeleted = { ...item };
      this.track(TRACKING_ACTIONS.REQUEST_DELETE_PACKAGE);
    },
    deleteItemConfirmation() {
      this.$emit('package:delete', this.itemToBeDeleted);
      this.track(TRACKING_ACTIONS.DELETE_PACKAGE);
      this.itemToBeDeleted = null;
    },
    deleteItemCanceled() {
      this.track(TRACKING_ACTIONS.CANCEL_DELETE_PACKAGE);
      this.itemToBeDeleted = null;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-col">
    <slot v-if="isListEmpty && !isLoading" name="empty-state"></slot>

    <div v-else-if="isLoading">
      <packages-list-loader />
    </div>

    <template v-else>
      <ul data-testid="packages-table" class="gl-pl-0">
        <li v-for="packageEntity in list" :key="packageEntity.id" class="gl-list-none">
          <packages-list-row
            :package-entity="packageEntity"
            :package-link="packageEntity._links.web_path"
            :is-group="isGroupPage"
            @packageToDelete="setItemToBeDeleted"
          />
        </li>
      </ul>

      <gl-pagination
        v-model="currentPage"
        :per-page="perPage"
        :total-items="totalItems"
        align="center"
        class="gl-mt-3 gl-w-full"
      />

      <delete-package-modal
        :item-to-be-deleted="itemToBeDeleted"
        @ok="deleteItemConfirmation"
        @cancel="deleteItemCanceled"
      />
    </template>
  </div>
</template>
