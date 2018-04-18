<script>
import { __ } from '~/locale';
import Flash from '~/flash';
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';

import COLUMNS from '../constants';

import TableHeader from './table_header.vue';
import TableBody from './table_body.vue';

export default {
  columns: COLUMNS,
  components: {
    LoadingIcon,
    TableHeader,
    TableBody,
  },
  props: {
    store: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: true,
    };
  },
  computed: {
    members() {
      return this.store.members;
    },
    sortOrders() {
      return this.store.sortOrders;
    },
  },
  mounted() {
    this.fetchContributedMembers();
  },
  methods: {
    fetchContributedMembers() {
      this.service
        .getContributedMembers()
        .then(res => res.data)
        .then(members => {
          this.store.setColumns(this.$options.columns);
          this.store.setMembers(members);
          this.isLoading = false;
        })
        .catch(() => {
          this.isLoading = false;
          Flash(__('Something went wrong while fetching group member contributions'));
        });
    },
    handleColumnClick(columnName) {
      this.store.sortMembers(columnName);
    },
  },
};
</script>

<template>
  <div class="group-member-contributions-container">
    <h3>{{ __('Contributions per group member') }}</h3>
    <loading-icon
      class="loading-animation prepend-top-20 append-bottom-20"
      size="2"
      v-if="isLoading"
      :label="__('Loading contribution stats for group members')"
    />
    <table
      v-else
      class="table gl-sortable"
    >
      <table-header
        :columns="$options.columns"
        :sort-orders="sortOrders"
        @onColumnClick="handleColumnClick"
      />
      <table-body
        :rows="members"
      />
    </table>
  </div>
</template>
