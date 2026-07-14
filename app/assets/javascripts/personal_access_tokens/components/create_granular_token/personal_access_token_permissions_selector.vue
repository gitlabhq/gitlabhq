<script>
import { isEqual, union } from 'lodash-es';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import getAccessTokenPermissions from '~/personal_access_tokens/graphql/get_access_token_permissions.query.graphql';
import { ACCESS_SCOPES, ACCESS_SCOPE_KEYS } from '~/personal_access_tokens/constants';
import { emptyByScope } from '~/personal_access_tokens/utils';
import PersonalAccessTokenResourcePanel from './personal_access_token_resource_panel.vue';
import PersonalAccessTokenGranularPermissionsList from './personal_access_token_granular_permissions_list.vue';

export default {
  name: 'PersonalAccessTokenPermissionsSelector',
  components: {
    PersonalAccessTokenResourcePanel,
    PersonalAccessTokenGranularPermissionsList,
  },
  props: {
    value: {
      type: Object,
      required: false,
      default: emptyByScope,
      validator: (value) => ACCESS_SCOPE_KEYS.every((key) => Array.isArray(value[key])),
    },
    error: {
      type: String,
      required: false,
      default: '',
    },
    aiPermissions: {
      type: Object,
      required: false,
      default: () => ({ suggested: emptyByScope(), removed: emptyByScope() }),
    },
  },
  emits: ['input'],
  data() {
    return {
      permissions: [],
      activeBoundary: 'namespace',
      selectedResources: emptyByScope(),
      pendingInput: null,
    };
  },
  apollo: {
    permissions: {
      query: getAccessTokenPermissions,
      update(data) {
        return data?.accessTokenPermissions || [];
      },
      error(error) {
        createAlert({
          message: this.$options.i18n.fetchError,
          captureError: true,
          error,
        });
      },
    },
  },
  computed: {
    isLoading() {
      return Boolean(this.$apollo.queries.permissions.loading);
    },
    permissionsByBoundary() {
      const result = emptyByScope();

      this.permissions.forEach((permission) => {
        ACCESS_SCOPES.forEach(({ key, boundaries }) => {
          if (boundaries.some((boundary) => permission.boundaries.includes(boundary))) {
            result[key].push(permission);
          }
        });
      });

      return result;
    },
  },
  watch: {
    value() {
      this.pendingInput = null;
      this.syncSelectedResources();
    },
    permissions() {
      this.syncSelectedResources();
      this.applyAiSuggestedPermissions(this.aiPermissions.suggested);
    },
    'aiPermissions.suggested': {
      immediate: true,
      handler(suggested) {
        this.applyAiSuggestedPermissions(suggested);
      },
    },
    'aiPermissions.removed': {
      immediate: true,
      handler(removed) {
        this.applyAiRemovedPermissions(removed);
      },
    },
  },
  methods: {
    handleResourcesInput(newResources) {
      const boundary = this.activeBoundary;
      const removedResources = this.selectedResources[boundary].filter(
        (resource) => !newResources.includes(resource),
      );

      this.selectedResources[boundary] = newResources;

      if (removedResources.length > 0) {
        this.removePermissionsForResources(boundary, removedResources);
      }
    },
    handleRemoveResource(boundary, resourceToRemove) {
      this.selectedResources[boundary] = this.selectedResources[boundary].filter(
        (resource) => resource !== resourceToRemove,
      );

      this.removePermissionsForResources(boundary, [resourceToRemove]);
    },
    removePermissionsForResources(boundary, removedResources) {
      const permissionsToRemove = this.permissionsByBoundary[boundary]
        .filter((permission) => removedResources.includes(permission.resource))
        .map((permission) => permission.name);

      this.emitPermissions(
        boundary,
        this.value[boundary].filter((permission) => !permissionsToRemove.includes(permission)),
      );
    },
    pendingValue() {
      return this.pendingInput || this.value;
    },
    emitInput(updated) {
      if (isEqual(updated, this.pendingValue())) return;

      this.pendingInput = updated;
      this.$emit('input', updated);
    },
    emitPermissions(boundary, permissionNames) {
      this.emitInput({ ...this.pendingValue(), [boundary]: permissionNames });
    },
    selectResourcesForNames(boundary, names) {
      const nameSet = new Set(names);
      if (!nameSet.size) return [];

      const matching = this.permissionsByBoundary[boundary].filter((permission) =>
        nameSet.has(permission.name),
      );

      this.selectedResources[boundary] = union(
        this.selectedResources[boundary],
        matching.map((permission) => permission.resource),
      );

      return matching;
    },
    syncSelectedResources() {
      ACCESS_SCOPES.forEach(({ key }) => {
        this.selectResourcesForNames(key, this.value[key]);
      });
    },
    applyAiSuggestedPermissions(suggested) {
      if (!this.permissions.length) return;

      const updated = { ...this.pendingValue() };

      ACCESS_SCOPES.forEach(({ key }) => {
        const names = this.selectResourcesForNames(key, suggested?.[key]).map(
          (permission) => permission.name,
        );

        updated[key] = union(updated[key], names);
      });

      this.emitInput(updated);
    },
    applyAiRemovedPermissions(removed) {
      const updated = { ...this.pendingValue() };

      ACCESS_SCOPES.forEach(({ key }) => {
        const removalSet = new Set(removed?.[key]);
        if (!removalSet.size) return;

        updated[key] = updated[key].filter((name) => !removalSet.has(name));
      });

      this.emitInput(updated);
    },
  },
  i18n: {
    selectorTitle: s__('AccessTokens|Resource and permission selector'),
    fetchError: s__('AccessTokens|Error loading permissions. Please refresh page.'),
  },
  scopes: ACCESS_SCOPES,
};
</script>

<template>
  <div>
    <div class="gl-rounded-base gl-border-1 gl-border-solid gl-border-section gl-@container/panel">
      <div
        class="gl-flex gl-items-center gl-justify-between gl-rounded-t-base gl-border-b-1 gl-border-b-section gl-bg-subtle gl-px-5 gl-py-3 gl-font-bold gl-border-b-solid"
      >
        {{ $options.i18n.selectorTitle }}
        <slot name="header-actions"></slot>
      </div>

      <div class="gl-flex gl-flex-col @md/panel:gl-flex-row">
        <personal-access-token-resource-panel
          class="gl-w-full gl-min-w-0 gl-p-4 @md/panel:gl-min-h-75 @md/panel:gl-w-2/5 @md/panel:gl-border-r-1 @md/panel:gl-border-r-section @md/panel:gl-border-r-solid"
          :active-boundary="activeBoundary"
          :permissions="permissionsByBoundary[activeBoundary]"
          :selected-resources="selectedResources"
          :is-loading="isLoading"
          @boundary-change="activeBoundary = $event"
          @resources-input="handleResourcesInput"
        />

        <div class="gl-w-full gl-min-w-0 gl-px-5 @md/panel:gl-w-3/5">
          <personal-access-token-granular-permissions-list
            v-for="scope in $options.scopes"
            :key="scope.key"
            :value="value[scope.key]"
            :permissions="permissionsByBoundary[scope.key]"
            :selected-resources="selectedResources[scope.key]"
            :scope="scope.key"
            @input="emitPermissions(scope.key, $event)"
            @remove-resource="handleRemoveResource(scope.key, $event)"
          />
        </div>
      </div>
    </div>
    <div v-if="error" class="invalid-feedback gl-block gl-pt-4">{{ error }}</div>
  </div>
</template>
