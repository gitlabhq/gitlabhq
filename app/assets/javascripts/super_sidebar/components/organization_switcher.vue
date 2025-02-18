<script>
import { GlDisclosureDropdown, GlAvatar, GlIcon, GlLoadingIcon, GlLink } from '@gitlab/ui';
import getCurrentUserOrganizations from '~/organizations/shared/graphql/queries/current_user_organizations.query.graphql';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  AVATAR_SHAPE_OPTION_RECT,
  ITEM_LOADING: {
    id: 'loading',
    text: 'loading',
    extraAttrs: { disabled: true, class: '!gl-shadow-none' },
  },
  ITEM_EMPTY: {
    id: 'empty',
    text: s__('Organization|No organizations available to switch to.'),
    extraAttrs: { disabled: true, class: '!gl-shadow-none gl-text-subtle' },
  },
  i18n: {
    currentOrganization: s__('Organization|Current organization'),
    switchOrganizations: s__('Organization|Switch organizations'),
    switchingNotSupportedMessage: s__(
      'Organization|Switching between organizations is not currently supported.',
    ),
    learnMore: __('Learn more'),
  },
  switchingOrganizationsDocsPath: helpPagePath('user/organization/_index.md', {
    anchor: 'switch-organizations',
  }),
  components: { GlDisclosureDropdown, GlAvatar, GlIcon, GlLoadingIcon, GlLink },
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
        // In Cells 1.0 users will not be able to switch organizations.
        // This means we don't need to fetch available organizations.
        // In Cells 1.5 we will update this to fetch the organizations.
        // See https://docs.gitlab.com/ee/architecture/blueprints/cells/iterations/cells-1.0.html#features-on-gitlabcom-that-are-not-supported-on-cells
        // and https://docs.gitlab.com/ee/architecture/blueprints/cells/iterations/cells-1.5.html
        return !this.organizationSwitchingEnabled || !this.dropdownShown;
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
    organizationSwitchingEnabled() {
      return gon?.features?.organizationSwitching;
    },
    loading() {
      return this.$apollo.queries.organizations.loading;
    },
    currentOrganization() {
      return window.gon.current_organization;
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

      // In Cells 1.0 users will not be able to switch organizations.
      // This means we don't render available organizations.
      // See https://docs.gitlab.com/ee/architecture/blueprints/cells/iterations/cells-1.0.html#features-on-gitlabcom-that-are-not-supported-on-cells
      // and https://docs.gitlab.com/ee/architecture/blueprints/cells/iterations/cells-1.5.html
      if (this.organizationSwitchingEnabled) {
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
      }

      return [currentOrganizationGroup];
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
  <gl-disclosure-dropdown :items="items" class="gl-block" placement="bottom" @shown="onShown">
    <template #toggle>
      <button
        class="user-bar-button organization-switcher-button gl-flex gl-w-full gl-items-center gl-gap-3 gl-rounded-base gl-border-none gl-p-3 gl-text-left gl-leading-1"
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
      <div v-else class="gl-flex gl-items-center gl-gap-3">
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

    <template v-if="!organizationSwitchingEnabled" #footer>
      <div class="gl-border-t gl-mt-2 gl-border-t-dropdown gl-px-4 gl-pt-3">
        <div class="gl-text-sm gl-font-bold">
          {{ $options.i18n.switchOrganizations }}
        </div>
        <div class="gl-py-3">
          <p class="gl-m-0 gl-text-sm gl-text-subtle">
            {{ $options.i18n.switchingNotSupportedMessage }}
            <gl-link class="gl-text-sm" :href="$options.switchingOrganizationsDocsPath">{{
              $options.i18n.learnMore
            }}</gl-link
            >.
          </p>
        </div>
      </div>
    </template>
  </gl-disclosure-dropdown>
</template>
