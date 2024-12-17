<script>
import { GlAvatarLabeled, GlTruncateText } from '@gitlab/ui';
import { __ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  name: 'OrganizationsListItem',
  i18n: {
    showMore: __('Show more'),
    showLess: __('Show less'),
  },
  truncateTextToggleButtonProps: { class: '!gl-text-sm' },
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
  methods: {
    getIdFromGraphQLId,
  },
};
</script>

<template>
  <li class="organization-row gl-border-b gl-flex gl-items-start gl-px-5 gl-py-5">
    <gl-avatar-labeled
      :size="48"
      :src="organization.avatarUrl"
      :entity-id="getIdFromGraphQLId(organization.id)"
      :entity-name="organization.name"
      :label="organization.name"
      :label-link="organization.webUrl"
      shape="rect"
    >
      <gl-truncate-text
        v-if="organization.descriptionHtml"
        :lines="2"
        :mobile-lines="2"
        :show-more-text="$options.i18n.showMore"
        :show-less-text="$options.i18n.showLess"
        :toggle-button-props="$options.truncateTextToggleButtonProps"
        class="gl-mt-2 gl-max-w-88"
      >
        <div
          v-safe-html:[$options.safeHtmlConfig]="organization.descriptionHtml"
          data-testid="organization-description-html"
          class="md gl-text-sm gl-text-subtle"
        ></div>
      </gl-truncate-text>
    </gl-avatar-labeled>
  </li>
</template>
