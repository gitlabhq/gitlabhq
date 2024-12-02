<script>
import AccessDropdown from '~/projects/settings/components/access_dropdown.vue';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import { ACCESS_LEVELS, LEVEL_TYPES } from './constants';

export const i18n = {
  failureMessage: s__('ProjectSettings|Failed to update tag!'),
};

export default {
  i18n,
  ACCESS_LEVELS,
  name: 'ProtectedTagEdit',
  components: {
    AccessDropdown,
  },
  props: {
    url: {
      type: String,
      required: true,
    },
    accessLevelsData: {
      type: Array,
      required: true,
    },
    hasLicense: {
      required: false,
      type: Boolean,
      default: true,
    },
    preselectedItems: {
      type: Array,
      required: false,
      default: () => [],
    },
    searchEnabled: {
      type: Boolean,
      required: false,
      default: true,
    },
    sectionSelector: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      selected: this.preselectedItems,
    };
  },
  methods: {
    hasChanges(permissions) {
      return permissions.some(({ id, _destroy }) => id === undefined || _destroy);
    },
    updatePermissions(permissions) {
      if (!this.hasChanges(permissions)) return;
      axios
        .patch(this.url, {
          protected_tag: {
            [`${ACCESS_LEVELS.CREATE}_attributes`]: permissions,
          },
        })
        .then(this.setSelected)
        .catch(() => {
          createAlert({
            message: i18n.failureMessage,
            parent: this.parentContainer,
          });
        });
    },
    setSelected({ data }) {
      if (!data) return;
      this.selected = data[ACCESS_LEVELS.CREATE].map(
        ({
          id,
          user_id: userId,
          group_id: groupId,
          access_level: accessLevel,
          deploy_key_id: deployKeyId,
        }) => {
          if (userId) {
            return {
              id,
              user_id: userId,
              type: LEVEL_TYPES.USER,
            };
          }

          if (groupId) {
            return {
              id,
              group_id: groupId,
              type: LEVEL_TYPES.GROUP,
            };
          }

          if (deployKeyId) {
            return {
              id,
              deploy_key_id: deployKeyId,
              type: LEVEL_TYPES.DEPLOY_KEY,
            };
          }

          return {
            id,
            access_level: accessLevel,
            type: LEVEL_TYPES.ROLE,
          };
        },
      );
    },
  },
};
</script>

<template>
  <access-dropdown
    toggle-class="js-allowed-to-create gl-max-w-34"
    test-id="allowed-to-create-dropdown"
    :has-license="hasLicense"
    :access-level="$options.ACCESS_LEVELS.CREATE"
    :access-levels-data="accessLevelsData"
    :preselected-items="selected"
    :search-enabled="searchEnabled"
    groups-with-project-access
    :block="true"
    :section-selector="sectionSelector"
    @hidden="updatePermissions"
  />
</template>
