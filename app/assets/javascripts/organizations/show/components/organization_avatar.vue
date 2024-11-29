<script>
import { GlAvatar, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { VISIBILITY_TYPE_ICON, ORGANIZATION_VISIBILITY_TYPE } from '~/visibility_level/constants';

export default {
  name: 'OrganizationAvatar',
  AVATAR_SHAPE_OPTION_RECT,
  i18n: {
    copyButtonText: s__('Organization|Copy organization ID'),
    orgId: s__('Organization|Org ID'),
  },
  components: { GlAvatar, GlIcon, ClipboardButton },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    organization: {
      type: Object,
      required: true,
    },
  },
  computed: {
    visibilityIcon() {
      return VISIBILITY_TYPE_ICON[this.organization.visibility];
    },
    visibilityTooltip() {
      return ORGANIZATION_VISIBILITY_TYPE[this.organization.visibility];
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center">
    <gl-avatar
      :entity-id="organization.id"
      :entity-name="organization.name"
      :shape="$options.AVATAR_SHAPE_OPTION_RECT"
      :size="64"
      :src="organization.avatar_url"
    />
    <div class="gl-ml-3">
      <div class="gl-flex gl-items-center">
        <h1 class="gl-m-0 gl-text-size-h1" data-testid="organization-name">
          {{ organization.name }}
        </h1>
        <gl-icon
          v-gl-tooltip="visibilityTooltip"
          :name="visibilityIcon"
          class="gl-ml-3"
          variant="subtle"
        />
      </div>
      <div class="gl-flex gl-items-center">
        <span class="gl-text-sm gl-text-subtle"
          >{{ $options.i18n.orgId }}: {{ organization.id }}</span
        >
        <clipboard-button
          class="gl-ml-2"
          category="tertiary"
          size="small"
          :title="$options.i18n.copyButtonText"
          :text="organization.id.toString()"
        />
      </div>
    </div>
  </div>
</template>
