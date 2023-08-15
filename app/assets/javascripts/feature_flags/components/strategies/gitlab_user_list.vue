<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { createNamespacedHelpers } from 'vuex';
import { s__ } from '~/locale';
import ParameterFormGroup from './parameter_form_group.vue';

const { mapActions, mapGetters, mapState } = createNamespacedHelpers('userLists');

const { fetchUserLists, setFilter } = mapActions(['fetchUserLists', 'setFilter']);

export default {
  components: {
    GlCollapsibleListbox,
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
    listboxItems() {
      return this.userLists.map((list) => ({
        value: list.id,
        text: list.name,
      }));
    },
  },
  mounted() {
    fetchUserLists.apply(this);
  },

  methods: {
    setFilter: debounce(setFilter, 250),
    onUserListChange(listId) {
      const list = this.userLists.find((userList) => userList.id === listId);
      this.$emit('change', {
        userList: list,
      });
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
      <gl-collapsible-listbox
        :id="inputId"
        :toggle-text="dropdownText"
        :loading="isLoading"
        :items="listboxItems"
        searchable
        :selected="userListId"
        @select="onUserListChange"
        @search="setFilter"
      />
    </template>
  </parameter-form-group>
</template>
