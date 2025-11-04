<script>
import { GlDisclosureDropdown, GlBadge } from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { __, s__ } from '~/locale';

export default {
  name: 'TokenCard',
  components: {
    CrudComponent,
    GlDisclosureDropdown,
    GlBadge,
  },
  inject: ['accessTokenNew'],
  computed: {
    newTokenDropdownItems() {
      return [
        {
          text: s__('AccessTokens|Fine-grained token'),
          href: this.accessTokenNew,
          description: s__(
            'AccessTokens|Limit scope to specific groups and projects and fine-grained permissions to resources.',
          ),
          badge: __('Beta'),
        },
        {
          text: s__('AccessTokens|Broad-access token'),
          href: this.accessTokenNew,
          description: s__(
            'AccessTokens|Scoped to all groups and projects with broad permissions to resources.',
          ),
        },
      ];
    },
  },
};
</script>

<template>
  <crud-component :title="s__('AccessTokens|Personal access tokens')">
    <template #actions>
      <gl-disclosure-dropdown
        :items="newTokenDropdownItems"
        :toggle-text="s__('AccessTokens|Generate token')"
        placement="bottom-end"
        fluid-width
      >
        <template #list-item="{ item }">
          <div class="gl-mx-3 gl-w-34">
            <div class="gl-font-bold">
              {{ item.text }}
              <gl-badge v-if="item.badge" class="gl-ml-2" variant="info">
                {{ item.badge }}
              </gl-badge>
            </div>
            <div class="gl-mt-2 gl-text-subtle">{{ item.description }}</div>
          </div>
        </template>
      </gl-disclosure-dropdown>
    </template>
  </crud-component>
</template>
