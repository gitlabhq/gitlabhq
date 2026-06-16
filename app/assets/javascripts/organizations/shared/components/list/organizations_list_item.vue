<script>
import { GlAvatarLabeled, GlBadge, GlTruncateText } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { ORGANIZATION_STATE_UNCONFIRMED } from '~/organizations/shared/constants';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  name: 'OrganizationsListItem',
  i18n: {
    showMore: __('Show more'),
    showLess: __('Show less'),
    unconfirmed: s__('Organization|Unconfirmed'),
  },
  truncateTextToggleButtonProps: { class: '!gl-text-sm' },
  components: {
    GlAvatarLabeled,
    GlBadge,
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
  computed: {
    isUnconfirmed() {
      return this.organization.state === ORGANIZATION_STATE_UNCONFIRMED;
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
      :label-link="organization.webPath"
      shape="rect"
    >
      <template v-if="isUnconfirmed" #meta>
        <div class="gl-p-1">
          <gl-badge variant="warning">{{ $options.i18n.unconfirmed }}</gl-badge>
        </div>
      </template>
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
