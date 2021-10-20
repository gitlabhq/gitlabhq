<script>
import { GlDropdown, GlDropdownItem, GlIcon, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';

const DEFAULT_PAGE_SIZES = [20, 50, 100];

export default {
  components: {
    PaginationLinks,
    GlDropdown,
    GlDropdownItem,
    GlIcon,
    GlSprintf,
  },
  props: {
    pageInfo: {
      required: true,
      type: Object,
    },
    pageSizes: {
      required: false,
      type: Array,
      default: () => DEFAULT_PAGE_SIZES,
    },
    itemsCount: {
      required: true,
      type: Number,
    },
  },

  computed: {
    humanizedTotal() {
      return this.pageInfo.total >= 1000 ? __('1000+') : this.pageInfo.total;
    },

    paginationInfo() {
      const { page, perPage } = this.pageInfo;
      const start = (page - 1) * perPage + 1;
      const end = start + this.itemsCount - 1;

      return { start, end };
    },
  },

  methods: {
    setPage(page) {
      this.$emit('set-page', page);
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center">
    <pagination-links :change="setPage" :page-info="pageInfo" class="gl-m-0" />
    <gl-dropdown category="tertiary" class="gl-ml-auto">
      <template #button-content>
        <span class="gl-font-weight-bold">
          <gl-sprintf :message="__('%{count} items per page')">
            <template #count>
              {{ pageInfo.perPage }}
            </template>
          </gl-sprintf>
        </span>
        <gl-icon class="gl-button-icon dropdown-chevron" name="chevron-down" />
      </template>
      <gl-dropdown-item v-for="size in pageSizes" :key="size" @click="$emit('set-page-size', size)">
        <gl-sprintf :message="__('%{count} items per page')">
          <template #count>
            {{ size }}
          </template>
        </gl-sprintf>
      </gl-dropdown-item>
    </gl-dropdown>
    <div class="gl-ml-2" data-testid="information">
      <gl-sprintf :message="s__('BulkImport|Showing %{start}-%{end} of %{total}')">
        <template #start>
          {{ paginationInfo.start }}
        </template>
        <template #end>
          {{ paginationInfo.end }}
        </template>
        <template #total>
          {{ humanizedTotal }}
        </template>
      </gl-sprintf>
    </div>
  </div>
</template>
