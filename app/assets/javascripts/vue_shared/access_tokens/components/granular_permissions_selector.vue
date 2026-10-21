<script>
import { isEqual, union } from 'lodash-es';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import getAccessTokenPermissions from '../graphql/get_access_token_permissions.query.graphql';
import { ACCESS_SCOPES, ACCESS_SCOPE_KEYS } from '../constants';
import { emptyByScope } from '../utils';
import GranularResourcePanel from './granular_resource_panel.vue';
import GranularPermissionsList from './granular_permissions_list.vue';

export default {
  name: 'GranularPermissionsSelector',
  components: {
    GranularResourcePanel,
    GranularPermissionsList,
  },
  props: {
    value: {
      type: Object,
      required: false,
      default: () => emptyByScope(),
      validator: (value) =>
        Object.entries(value).every(
          ([key, permissions]) => ACCESS_SCOPE_KEYS.includes(key) && Array.isArray(permissions),
        ),
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
    scopes: {
      type: Array,
      required: false,
      default: () => ACCESS_SCOPES,
      validator: (scopes) =>
        scopes.length > 0 && scopes.every(({ key }) => ACCESS_SCOPE_KEYS.includes(key)),
    },
  },
  emits: ['input'],
  data() {
    return {
      permissions: [],
      activeBoundary: this.scopes[0].key,
      selectedResources: emptyByScope(this.scopes.map(({ key }) => key)),
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
    scopeKeys() {
      return this.scopes.map(({ key }) => key);
    },
    selectedPermissions() {
      // Consumers may pass only the keys of their scopes; a missing scope reads as empty
      return { ...emptyByScope(this.scopeKeys), ...this.value };
    },
    permissionsByBoundary() {
      const result = emptyByScope(this.scopeKeys);

      this.permissions.forEach((permission) => {
        this.scopes.forEach(({ key, boundaries }) => {
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
        this.selectedPermissions[boundary].filter(
          (permission) => !permissionsToRemove.includes(permission),
        ),
      );
    },
    pendingValue() {
      return this.pendingInput || this.selectedPermissions;
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
      this.scopes.forEach(({ key }) => {
        this.selectResourcesForNames(key, this.selectedPermissions[key]);
      });
    },
    applyAiSuggestedPermissions(suggested) {
      if (!this.permissions.length) return;

      const updated = { ...this.pendingValue() };

      this.scopes.forEach(({ key }) => {
        const names = this.selectResourcesForNames(key, suggested?.[key]).map(
          (permission) => permission.name,
        );

        updated[key] = union(updated[key], names);
      });

      this.emitInput(updated);
    },
    applyAiRemovedPermissions(removed) {
      const updated = { ...this.pendingValue() };

      this.scopes.forEach(({ key }) => {
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
        <granular-resource-panel
          class="gl-w-full gl-min-w-0 gl-p-4 @md/panel:gl-min-h-75 @md/panel:gl-w-2/5 @md/panel:gl-border-r-1 @md/panel:gl-border-r-section @md/panel:gl-border-r-solid"
          :scopes="scopes"
          :active-boundary="activeBoundary"
          :permissions="permissionsByBoundary[activeBoundary]"
          :selected-resources="selectedResources"
          :is-loading="isLoading"
          @boundary-change="activeBoundary = $event"
          @resources-input="handleResourcesInput"
        />

        <div class="gl-w-full gl-min-w-0 gl-px-5 @md/panel:gl-w-3/5">
          <granular-permissions-list
            v-for="scope in scopes"
            :key="scope.key"
            :value="selectedPermissions[scope.key]"
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
