<script>
import { GlButton, GlCollapse, GlIcon, GlLink } from '@gitlab/ui';
import { camelCase, xor } from 'lodash-es';
import { groupPermissionsByResourceAndCategory } from '~/personal_access_tokens/utils';
import { s__ } from '~/locale';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { getTypeFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT_NAMESPACE } from '~/graphql_shared/constants';
import {
  ACCESS_PERSONAL_PROJECTS_ENUM,
  ACCESS_SELECTED_MEMBERSHIPS_ENUM,
  ACCESS_ALL_MEMBERSHIPS_ENUM,
  ACCESS_USER_ENUM,
} from '../constants';

export default {
  name: 'PersonalAccessTokenGranularScopes',
  components: {
    GlButton,
    GlCollapse,
    GlIcon,
    GlLink,
    ProjectAvatar,
  },
  props: {
    scopes: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      expanded: [],
    };
  },
  computed: {
    sections() {
      const sectionDefs = [
        {
          type: 'namespace',
          accessList: [
            ACCESS_PERSONAL_PROJECTS_ENUM,
            ACCESS_SELECTED_MEMBERSHIPS_ENUM,
            ACCESS_ALL_MEMBERSHIPS_ENUM,
          ],
        },
        { type: 'user', accessList: [ACCESS_USER_ENUM] },
      ];

      return sectionDefs.map(({ type, accessList }) => {
        const scopes = this.scopes.filter(({ access }) => accessList.includes(access));

        const allPermissions = scopes.flatMap(({ permissions }) => permissions);
        const categories = groupPermissionsByResourceAndCategory(allPermissions);
        const actionsCount = allPermissions.length;

        return {
          type,
          access: scopes.at(0)?.access,
          namespaces: scopes.map(({ namespace }) => namespace).filter(Boolean),
          categories,
          actionsCount,
        };
      });
    },
  },
  methods: {
    namespaceAccessDescription(access) {
      return this.$options.i18n.namespace[camelCase(access)];
    },
    namespaceIcon(namespaceId) {
      return getTypeFromGraphQLId(namespaceId) === TYPENAME_PROJECT_NAMESPACE ? 'project' : 'group';
    },
    toggle(key) {
      this.expanded = xor(this.expanded, [key]);
    },
    isExpanded(key) {
      return this.expanded.includes(key);
    },
    formatActions(actions) {
      return actions.map(({ name }) => name).join(', ');
    },
  },
  i18n: {
    scope: s__('AccessTokens|Token scope'),
    namespace: {
      access: s__('AccessTokens|Group and project access'),
      permissions: s__('AccessTokens|Group and project permissions'),
      personalProjects: s__('AccessTokens|Only my personal projects, including future ones'),
      allMemberships: s__(
        "AccessTokens|All groups and projects that I'm a member of, including future ones",
      ),
      selectedMemberships: s__("AccessTokens|Only specific group or projects that I'm a member of"),
    },
    user: {
      permissions: s__('AccessTokens|User permissions'),
    },
    noResources: s__('AccessTokens|No resources added'),
  },
};
</script>

<template>
  <div>
    <div v-for="section in sections" :key="section.type" class="gl-border-b gl-py-4">
      <div class="gl-pl-5">
        <template v-if="namespaceAccessDescription(section.access)">
          <div class="gl-mb-2 gl-font-bold">{{ $options.i18n.namespace.access }}</div>
          <div class="gl-mb-5 gl-text-subtle">
            <gl-icon name="group" />
            {{ namespaceAccessDescription(section.access) }}
          </div>

          <div v-for="namespace in section.namespaces" :key="namespace.id" class="gl-mb-5">
            <gl-icon :name="namespaceIcon(namespace.id)" class="gl-mr-3 gl-shrink-0" />
            <project-avatar
              :alt="namespace.name"
              :project-id="namespace.id"
              :project-name="namespace.fullName"
              :project-avatar-url="namespace.avatarUrl"
              class="gl-mr-3"
              :size="24"
            />
            <gl-link :href="namespace.webUrl">{{ namespace.fullName }}</gl-link>
          </div>
        </template>
      </div>

      <gl-button category="tertiary" class="gl-font-bold" @click="toggle(section.type)">
        <gl-icon :name="isExpanded(section.type) ? 'chevron-down' : 'chevron-right'" />
        {{ $options.i18n[section.type].permissions }} ({{ section.actionsCount }})
      </gl-button>

      <gl-collapse :visible="isExpanded(section.type)">
        <span v-if="!section.categories.length" class="gl-my-2 gl-ml-7 gl-text-subtle">{{
          $options.i18n.noResources
        }}</span>

        <div v-for="category in section.categories" :key="category.key" class="gl-ml-7 gl-py-3">
          <span>{{ category.name }}</span>
          <div v-for="resource in category.resources" :key="resource.key" class="gl-my-2">
            <gl-icon name="check-sm" variant="success" class="gl-mr-2" />
            <span>{{ resource.name }}:</span>
            <span class="gl-capitalize">{{ formatActions(resource.actions) }}</span>
          </div>
        </div>
      </gl-collapse>
    </div>
  </div>
</template>
