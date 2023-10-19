<script>
import { GlAvatarLabeled, GlTruncateText } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  name: 'OrganizationsListItem',
  components: {
    GlAvatarLabeled,
    GlTruncateText,
  },
  safeHtmlConfig: {
    ADD_TAGS: ['gl-emoji'],
  },
  directives: {
    SafeHtml,
  },
  props: {
    organization: {
      type: Object,
      required: true,
    },
  },
  avatarSize: { default: 32, md: 48 },
  getIdFromGraphQLId,
};
</script>

<template>
  <li class="organization-row gl-py-3 gl-border-b gl-display-flex gl-align-items-flex-start">
    <gl-avatar-labeled
      :size="$options.avatarSize"
      :src="organization.avatarUrl"
      :entity-id="$options.getIdFromGraphQLId(organization.id)"
      :entity-name="organization.name"
      :label="organization.name"
      :label-link="organization.webUrl"
      shape="rect"
    >
      <gl-truncate-text
        v-if="organization.descriptionHtml"
        :lines="2"
        :mobile-lines="2"
        class="gl-mt-2"
      >
        <div
          v-safe-html:[$options.safeHtmlConfig]="organization.descriptionHtml"
          data-testid="organization-description-html"
          class="organization-description gl-text-secondary gl-font-sm"
        ></div>
      </gl-truncate-text>
    </gl-avatar-labeled>
  </li>
</template>
