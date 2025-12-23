<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import { groupBy, mapValues, camelCase } from 'lodash';
import { s__ } from '~/locale';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { getTypeFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT_NAMESPACE } from '~/graphql_shared/constants';
import {
  ACCESS_PERSONAL_PROJECTS_ENUM,
  ACCESS_SELECTED_MEMBERSHIPS_ENUM,
  ACCESS_ALL_MEMBERSHIPS_ENUM,
} from '../constants';

export default {
  name: 'PersonalAccessTokenGranularScopes',
  components: { GlIcon, GlLink, ProjectAvatar },
  props: {
    scopes: {
      type: Array,
      required: true,
    },
  },
  computed: {
    scopesGroupedByAccess() {
      return groupBy(this.scopes, 'access');
    },
  },
  methods: {
    isScopedToGroup(access) {
      return [
        ACCESS_PERSONAL_PROJECTS_ENUM,
        ACCESS_SELECTED_MEMBERSHIPS_ENUM,
        ACCESS_ALL_MEMBERSHIPS_ENUM,
      ].includes(access);
    },
    groupAccessDescription(access) {
      return this.$options.i18n.group[camelCase(access)];
    },
    permissionsGroupedByResource(scopes) {
      const { permissions } = scopes.at(0);

      return mapValues(groupBy(permissions, 'resource'), (perms) => perms.map((p) => p.action));
    },
    permissionsText(access) {
      if (this.isScopedToGroup(access)) {
        return this.$options.i18n.group.permissions;
      }

      return this.$options.i18n[access.toLowerCase()]?.permissions;
    },
    formatActions(actions) {
      return actions.join(', ');
    },
    formatResource(resource) {
      return resource.split('_').join(' ');
    },
    namespaceIcon(namespaceId) {
      const namespaceType = getTypeFromGraphQLId(namespaceId);

      if (namespaceType === TYPENAME_PROJECT_NAMESPACE) {
        return 'project';
      }

      return 'group';
    },
  },
  i18n: {
    scope: s__('AccessTokens|Token scope'),
    group: {
      access: s__('AccessTokens|Group and project access'),
      permissions: s__('AccessTokens|Group and project permissions'),
      personalProjects: s__('AccessTokens|Only personal projects'),
      allMemberships: s__("AccessTokens|All groups and projects that I'm a member of"),
      selectedMemberships: s__("AccessTokens|Only specific group or projects that I'm a member of"),
    },
    user: {
      permissions: s__('AccessTokens|User permissions'),
    },
    instance: {
      permissions: s__('AccessTokens|Instance permissions'),
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-heading-4 gl-mb-4">{{ $options.i18n.scope }}</div>

    <div v-for="(scopeList, access) in scopesGroupedByAccess" :key="access">
      <div v-if="isScopedToGroup(access)">
        <div class="gl-font-bold">{{ $options.i18n.group.access }}</div>
        <div class="gl-mt-2 gl-text-subtle">{{ groupAccessDescription(access) }}</div>

        <div v-for="(scope, index) in scopeList" :key="index" class="gl-mt-4">
          <div v-if="scope.namespace" class="gl-inline-flex gl-items-center">
            <gl-icon :name="namespaceIcon(scope.namespace.id)" class="gl-mr-3 gl-shrink-0" />
            <project-avatar
              :alt="scope.namespace.name"
              :project-id="scope.namespace.id"
              :project-name="scope.namespace.fullName"
              :project-avatar-url="scope.namespace.avatarUrl"
              class="gl-mr-3"
              :size="24"
            />
            <gl-link :href="scope.namespace.webUrl">
              {{ scope.namespace.fullName }}
            </gl-link>
          </div>
        </div>
      </div>

      <div class="gl-mt-6 gl-font-bold">{{ permissionsText(access) }}</div>

      <div v-for="(actions, resource) in permissionsGroupedByResource(scopeList)" :key="resource">
        <div class="gl-mt-2">
          <gl-icon name="check-sm" variant="success" class="gl-mr-2" />
          <span class="gl-capitalize">
            {{ formatActions(actions) }}: {{ formatResource(resource) }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
