<script>
import { GlDisclosureDropdown, GlAvatar, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import getCurrentUserOrganizations from '~/organizations/shared/graphql/queries/organizations.query.graphql';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { defaultOrganization } from '~/organizations/mock_data';
import { s__ } from '~/locale';

export default {
  AVATAR_SHAPE_OPTION_RECT,
  ITEM_LOADING: {
    id: 'loading',
    text: 'loading',
    extraAttrs: { disabled: true, class: 'gl-shadow-none!' },
  },
  ITEM_EMPTY: {
    id: 'empty',
    text: s__('Organization|No organizations available to switch to.'),
    extraAttrs: { disabled: true, class: 'gl-shadow-none! gl-text-secondary' },
  },
  i18n: {
    currentOrganization: s__('Organization|Current organization'),
    switchOrganizations: s__('Organization|Switch organizations'),
  },
  components: { GlDisclosureDropdown, GlAvatar, GlIcon, GlLoadingIcon },
  data() {
    return {
      organizations: {},
      dropdownShown: false,
    };
  },
  apollo: {
    organizations: {
      query: getCurrentUserOrganizations,
      update(data) {
        return data.currentUser.organizations;
      },
      skip() {
        return !this.dropdownShown;
      },
      error() {
        this.organizations = {
          nodes: [],
          pageInfo: {},
        };
      },
    },
  },
  computed: {
    loading() {
      return this.$apollo.queries.organizations.loading;
    },
    currentOrganization() {
      // TODO - use `gon.current_organization` when backend supports it.
      // https://gitlab.com/gitlab-org/gitlab/-/issues/437095
      return defaultOrganization;
    },
    nodes() {
      return this.organizations.nodes || [];
    },
    items() {
      const currentOrganizationGroup = {
        name: this.$options.i18n.currentOrganization,
        items: [
          {
            id: this.currentOrganization.id,
            text: this.currentOrganization.name,
            href: this.currentOrganization.web_url,
            avatarUrl: this.currentOrganization.avatar_url,
          },
        ],
      };

      if (this.loading || !this.dropdownShown) {
        return [
          currentOrganizationGroup,
          {
            name: this.$options.i18n.switchOrganizations,
            items: [this.$options.ITEM_LOADING],
          },
        ];
      }

      const items = this.nodes
        .map((node) => ({
          id: getIdFromGraphQLId(node.id),
          text: node.name,
          href: node.webUrl,
          avatarUrl: node.avatarUrl,
        }))
        .filter((item) => item.id !== this.currentOrganization.id);

      return [
        currentOrganizationGroup,
        {
          name: this.$options.i18n.switchOrganizations,
          items: items.length ? items : [this.$options.ITEM_EMPTY],
        },
      ];
    },
  },
  methods: {
    onShown() {
      this.dropdownShown = true;
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown :items="items" class="gl-display-block" @shown="onShown">
    <template #toggle>
      <button
        class="organization-switcher-button gl-display-flex gl-align-items-center gl-gap-3 gl-p-3 gl-rounded-base gl-border-none gl-line-height-1 gl-w-full"
        data-testid="toggle-button"
      >
        <gl-avatar
          :size="24"
          :shape="$options.AVATAR_SHAPE_OPTION_RECT"
          :entity-id="currentOrganization.id"
          :entity-name="currentOrganization.name"
          :src="currentOrganization.avatar_url"
        />
        <span>{{ currentOrganization.name }}</span>
        <gl-icon class="gl-button-icon gl-new-dropdown-chevron" name="chevron-down" />
      </button>
    </template>

    <template #list-item="{ item }">
      <gl-loading-icon v-if="item.id === $options.ITEM_LOADING.id" />
      <span v-else-if="item.id === $options.ITEM_EMPTY.id">{{ item.text }}</span>
      <div v-else class="gl-display-flex gl-align-items-center gl-gap-3">
        <gl-avatar
          :size="24"
          :shape="$options.AVATAR_SHAPE_OPTION_RECT"
          :entity-id="item.id"
          :entity-name="item.text"
          :src="item.avatarUrl"
        />
        <span>{{ item.text }}</span>
      </div>
    </template>
  </gl-disclosure-dropdown>
</template>
