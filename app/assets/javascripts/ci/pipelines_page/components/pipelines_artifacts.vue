<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export const i18n = {
  artifacts: __('Artifacts'),
  artifactSectionHeader: __('Download artifacts'),
};

export default {
  i18n,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlDisclosureDropdown,
  },
  inject: {
    artifactsEndpoint: {
      default: '',
    },
    artifactsEndpointPlaceholder: {
      default: '',
    },
  },
  props: {
    pipelineId: {
      type: Number,
      required: true,
    },
    artifacts: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    items() {
      return [
        {
          name: this.$options.i18n.artifactSectionHeader,
          items: this.artifacts.map(({ name, path }) => ({
            text: name,
            href: path,
            extraAttrs: {
              download: '',
              rel: 'nofollow',
            },
          })),
        },
      ];
    },
    shouldShowDropdown() {
      return this.artifacts?.length;
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    v-if="shouldShowDropdown"
    v-gl-tooltip
    class="gl-text-left"
    :title="$options.i18n.artifacts"
    :toggle-text="$options.i18n.artifacts"
    :aria-label="$options.i18n.artifacts"
    icon="download"
    placement="bottom-end"
    text-sr-only
    :items="items"
    data-testid="artifacts-dropdown"
  />
</template>

<style scoped>
/* TODO: Use max-height prop when gitlab-ui got updated.
See https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2374 */
::v-deep .gl-new-dropdown-inner {
  max-height: 310px !important;
}
</style>
