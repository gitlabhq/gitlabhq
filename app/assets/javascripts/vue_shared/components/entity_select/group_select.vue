<script>
import { GlAlert } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import axios from '~/lib/utils/axios_utils';
import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';
import Api, { DEFAULT_PER_PAGE } from '~/api';
import { groupsPath } from './utils';
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
    label: {
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
      type: String,
      required: false,
      default: null,
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
      type: String,
      required: false,
      default: null,
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
      try {
        const { data = [], headers } = await axios.get(
          Api.buildUrl(groupsPath(this.groupsFilter, this.parentGroupID)),
          {
            params: {
              search: searchString,
              per_page: DEFAULT_PER_PAGE,
              page,
            },
          },
        );
        groups = data.map((group) => ({
          ...group,
          text: group.full_name,
          value: String(group.id),
        }));

        totalPages = parseIntPagination(normalizeHeaders(headers)).totalPages;
      } catch (error) {
        this.handleError({ message: FETCH_GROUPS_ERROR, error });
      }
      return { items: groups, totalPages };
    },
    async fetchGroupName(groupId) {
      let groupName = '';
      try {
        const group = await Api.group(groupId);
        groupName = group.full_name;
      } catch (error) {
        this.handleError({ message: FETCH_GROUP_ERROR, error });
      }
      return groupName;
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
    toggleText: GROUP_TOGGLE_TEXT,
    selectGroup: GROUP_HEADER_TEXT,
  },
};
</script>

<template>
  <entity-select
    :label="label"
    :input-name="inputName"
    :input-id="inputId"
    :initial-selection="initialSelection"
    :clearable="clearable"
    :header-text="$options.i18n.selectGroup"
    :default-toggle-text="$options.i18n.toggleText"
    :fetch-items="fetchGroups"
    :fetch-initial-selection-text="fetchGroupName"
  >
    <template #error>
      <gl-alert v-if="errorMessage" class="gl-mb-3" variant="danger" @dismiss="dismissError">{{
        errorMessage
      }}</gl-alert>
    </template>
    <template #list-item="{ item }">
      <div class="gl-font-weight-bold">
        {{ item.full_name }}
      </div>
      <div class="gl-text-gray-300">{{ item.full_path }}</div>
    </template>
  </entity-select>
</template>
