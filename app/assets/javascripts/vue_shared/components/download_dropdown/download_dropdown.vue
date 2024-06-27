<script>
import { GlDisclosureDropdown, GlDisclosureDropdownGroup, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    downloadLinks: {
      type: Array,
      required: true,
    },
    downloadArtifacts: {
      type: Array,
      required: true,
    },
    cssClass: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    hasDownloadLinks() {
      return this.downloadLinks.length;
    },
    hasDownloadArtifacts() {
      return this.downloadArtifacts.length;
    },
    showDownloadArtifactsBorder() {
      return this.hasDownloadLinks > 0;
    },
    sourceCodeGroup() {
      const items = this.downloadLinks.map((link) => ({
        text: link.text,
        href: link.path,
        extraAttrs: {
          rel: 'nofollow',
          download: '',
        },
      }));

      return {
        name: this.$options.i18n.downloadSourceCode,
        items,
      };
    },
    artifactsGroup() {
      const items = this.downloadArtifacts.map((link) => ({
        text: link.text,
        href: link.path,
        extraAttrs: {
          rel: 'nofollow',
          download: '',
        },
      }));

      return {
        name: this.$options.i18n.downloadArtifacts,
        items,
      };
    },
  },
  methods: {
    closeDropdown() {
      this.$refs.dropdown.close();
    },
  },
  i18n: {
    defaultLabel: __('Download'),
    downloadSourceCode: __('Download source code'),
    downloadArtifacts: __('Download artifacts'),
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    ref="dropdown"
    v-gl-tooltip.hover
    :toggle-text="$options.i18n.defaultLabel"
    :title="$options.i18n.defaultLabel"
    category="secondary"
    placement="bottom-end"
    icon="download"
    text-sr-only
    fluid-width
    :class="cssClass"
    data-testid="download-source-code-button"
    :auto-close="false"
  >
    <gl-disclosure-dropdown-group
      v-if="hasDownloadLinks"
      :group="sourceCodeGroup"
      data-testid="source-code-group"
      @action="closeDropdown"
    />
    <gl-disclosure-dropdown-group
      v-if="hasDownloadArtifacts"
      :group="artifactsGroup"
      :bordered="showDownloadArtifactsBorder"
      data-testid="artifacts-group"
      @action="closeDropdown"
    />
  </gl-disclosure-dropdown>
</template>
