<script>
import { GlFormSelect } from '@gitlab/ui';
import { s__ } from '~/locale';
import ParameterFormGroup from './parameter_form_group.vue';

export default {
  components: {
    GlFormSelect,
    ParameterFormGroup,
  },
  props: {
    strategy: {
      required: true,
      type: Object,
    },
    userLists: {
      required: false,
      type: Array,
      default: () => [],
    },
  },
  translations: {
    rolloutUserListLabel: s__('FeatureFlag|List'),
    rolloutUserListDescription: s__('FeatureFlag|Select a user list'),
    rolloutUserListNoListError: s__('FeatureFlag|There are no configured user lists'),
  },
  computed: {
    userListOptions() {
      return this.userLists.map(({ name, id }) => ({ value: id, text: name }));
    },
    hasUserLists() {
      return this.userListOptions.length > 0;
    },
    userListId() {
      return this.strategy?.userListId ?? '';
    },
  },
  methods: {
    onUserListChange(list) {
      this.$emit('change', {
        userListId: list,
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
      <gl-form-select
        :id="inputId"
        :value="userListId"
        :options="userListOptions"
        @change="onUserListChange"
      />
    </template>
  </parameter-form-group>
</template>
