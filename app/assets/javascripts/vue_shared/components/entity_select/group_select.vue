<script>
import { GlAlert } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from '~/lib/utils/axios_utils';
import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';
import Api, { DEFAULT_PER_PAGE } from '~/api';
import { groupsPath, initialSelectionPropValidator } from './utils';
import {
  GROUP_TOGGLE_TEXT,
  GROUP_HEADER_TEXT,
  FETCH_GROUPS_ERROR,
  FETCH_GROUP_ERROR,
} from './constants';
import EntitySelect from './entity_select.vue';

export default {
  components: {
    GlAlert,
    EntitySelect,
  },
  props: {
    apiParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    block: {
      type: Boolean,
      required: false,
      default: false,
    },
    label: {
      type: String,
      required: false,
      default: '',
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
    inputName: {
      type: String,
      required: true,
    },
    inputId: {
      type: String,
      required: true,
    },
    initialSelection: {
      type: [String, Number, Object],
      required: false,
      default: null,
      validator: initialSelectionPropValidator,
    },
    clearable: {
      type: Boolean,
      required: false,
      default: false,
    },
    parentGroupID: {
      type: String,
      required: false,
      default: null,
    },
    groupsFilter: {
      type: String, // Two supported values: `descendant_groups` and `subgroups` See app/assets/javascripts/vue_shared/components/entity_select/utils.js.
      required: false,
      default: null,
    },
    emptyText: {
      type: String,
      required: false,
      default: GROUP_TOGGLE_TEXT,
    },
  },
  data() {
    return {
      errorMessage: '',
    };
  },
  methods: {
    async fetchGroups(searchString = '', page = 1) {
      let groups = [];
      let totalPages = 0;
      const params = {
        search: searchString,
        per_page: DEFAULT_PER_PAGE,
        page,
        ...this.apiParams,
      };
      try {
        const url = groupsPath(this.groupsFilter, this.parentGroupID);
        const { data = [], headers } = await axios.get(url, { params });
        groups = data.map((group) => this.mapGroupData(group));

        totalPages = parseIntPagination(normalizeHeaders(headers)).totalPages;
      } catch (error) {
        this.handleError({ message: FETCH_GROUPS_ERROR, error });
      }
      return { items: groups, totalPages };
    },
    async fetchInitialGroup(groupId) {
      try {
        const group = await Api.group(groupId);

        return this.mapGroupData(group);
      } catch (error) {
        this.handleError({ message: FETCH_GROUP_ERROR, error });

        return {};
      }
    },
    mapGroupData(group) {
      return { ...group, text: group.full_name, value: String(group.id) };
    },
    handleError({ message, error }) {
      Sentry.captureException(error);
      this.errorMessage = message;
    },
    dismissError() {
      this.errorMessage = '';
    },
  },
  i18n: {
    selectGroup: GROUP_HEADER_TEXT,
  },
};
</script>

<template>
  <entity-select
    :label="label"
    :description="description"
    :input-name="inputName"
    :input-id="inputId"
    :initial-selection="initialSelection"
    :clearable="clearable"
    :header-text="$options.i18n.selectGroup"
    :default-toggle-text="emptyText"
    :fetch-items="fetchGroups"
    :fetch-initial-selection="fetchInitialGroup"
    :block="block"
    v-on="$listeners"
  >
    <template #error>
      <gl-alert v-if="errorMessage" class="gl-mb-3" variant="danger" @dismiss="dismissError">{{
        errorMessage
      }}</gl-alert>
    </template>
    <template #list-item="{ item }">
      <div class="gl-font-bold">
        {{ item.full_name }}
      </div>
      <div class="gl-text-gray-300">{{ item.full_path }}</div>
    </template>
  </entity-select>
</template>
