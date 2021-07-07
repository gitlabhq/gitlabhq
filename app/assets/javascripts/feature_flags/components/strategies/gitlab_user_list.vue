<script>
import { GlDropdown, GlDropdownItem, GlLoadingIcon, GlSearchBoxByType } from '@gitlab/ui';
import { debounce } from 'lodash';
import { createNamespacedHelpers } from 'vuex';
import { s__ } from '~/locale';
import ParameterFormGroup from './parameter_form_group.vue';

const { mapActions, mapGetters, mapState } = createNamespacedHelpers('userLists');

const { fetchUserLists, setFilter } = mapActions(['fetchUserLists', 'setFilter']);

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlLoadingIcon,
    GlSearchBoxByType,
    ParameterFormGroup,
  },
  props: {
    strategy: {
      required: true,
      type: Object,
    },
  },
  translations: {
    rolloutUserListLabel: s__('FeatureFlag|User List'),
    rolloutUserListDescription: s__('FeatureFlag|Select a user list'),
    rolloutUserListNoListError: s__('FeatureFlag|There are no configured user lists'),
    defaultDropdownText: s__('FeatureFlags|No user list selected'),
  },
  computed: {
    ...mapGetters(['hasUserLists', 'isLoading', 'hasError', 'userListOptions']),
    ...mapState(['filter', 'userLists']),
    userListId() {
      return this.strategy?.userList?.id ?? '';
    },
    dropdownText() {
      return this.strategy?.userList?.name ?? this.$options.translations.defaultDropdownText;
    },
  },
  mounted() {
    fetchUserLists.apply(this);
  },
  methods: {
    setFilter: debounce(setFilter, 250),
    fetchUserLists: debounce(fetchUserLists, 250),
    onUserListChange(list) {
      this.$emit('change', {
        userList: list,
      });
    },
    isSelectedUserList({ id }) {
      return id === this.userListId;
    },
    setFocus() {
      this.$refs.searchBox.focusInput();
    },
  },
};
</script>
<template>
  <parameter-form-group
    :state="hasUserLists"
    :invalid-feedback="$options.translations.rolloutUserListNoListError"
    :label="$options.translations.rolloutUserListLabel"
    :description="hasUserLists ? $options.translations.rolloutUserListDescription : ''"
  >
    <template #default="{ inputId }">
      <gl-dropdown :id="inputId" :text="dropdownText" @shown="setFocus">
        <gl-search-box-by-type
          ref="searchBox"
          class="gl-m-3"
          :value="filter"
          @input="setFilter"
          @focus="fetchUserLists"
          @keyup="fetchUserLists"
        />
        <gl-loading-icon v-if="isLoading" size="sm" />
        <gl-dropdown-item
          v-for="list in userLists"
          :key="list.id"
          :is-checked="isSelectedUserList(list)"
          is-check-item
          @click="onUserListChange(list)"
        >
          {{ list.name }}
        </gl-dropdown-item>
      </gl-dropdown>
    </template>
  </parameter-form-group>
</template>
