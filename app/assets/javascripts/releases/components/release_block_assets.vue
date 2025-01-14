<script>
import { GlTooltipDirective, GlLink, GlButton, GlCollapse, GlIcon, GlBadge } from '@gitlab/ui';
import { difference, get } from 'lodash';
import { __, s__, sprintf } from '~/locale';
import { InternalEvents } from '~/tracking';
import { ASSET_LINK_TYPE, CLICK_EXPAND_ASSETS_ON_RELEASE_PAGE } from '../constants';

export default {
  name: 'ReleaseBlockAssets',
  components: {
    GlLink,
    GlButton,
    GlCollapse,
    GlIcon,
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    assets: {
      type: Object,
      required: true,
    },
    expanded: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      isAssetsExpanded: this.expanded,
    };
  },
  computed: {
    imageLinks() {
      return this.linksForType(ASSET_LINK_TYPE.IMAGE);
    },
    packageLinks() {
      return this.linksForType(ASSET_LINK_TYPE.PACKAGE);
    },
    runbookLinks() {
      return this.linksForType(ASSET_LINK_TYPE.RUNBOOK);
    },
    otherLinks() {
      return difference(this.assets.links, [
        ...this.imageLinks,
        ...this.packageLinks,
        ...this.runbookLinks,
      ]);
    },
    sections() {
      return [
        {
          links: get(this.assets, 'sources', []).map((s) => ({
            url: s.url,
            name: sprintf(__('Source code (%{fileExtension})'), { fileExtension: s.format }),
          })),
          iconName: 'doc-code',
        },
        {
          title: s__('ReleaseAssetLinkType|Images'),
          links: this.imageLinks,
          iconName: 'container-image',
        },
        {
          title: s__('ReleaseAssetLinkType|Packages'),
          links: this.packageLinks,
          iconName: 'package',
        },
        {
          title: s__('ReleaseAssetLinkType|Runbooks'),
          links: this.runbookLinks,
          iconName: 'book',
        },
        {
          title: s__('ReleaseAssetLinkType|Other'),
          links: this.otherLinks,
          iconName: 'link',
        },
      ].filter((section) => section.links.length > 0);
    },
  },
  methods: {
    toggleAssetsExpansion() {
      this.isAssetsExpanded = !this.isAssetsExpanded;

      if (this.isAssetsExpanded) {
        this.trackEvent(CLICK_EXPAND_ASSETS_ON_RELEASE_PAGE);
      }
    },
    linksForType(type) {
      return this.assets.links.filter((l) => l.linkType === type);
    },
    getTooltipTitle(section) {
      return section.title
        ? this.$options.externalLinkTooltipText
        : this.$options.downloadTooltipText;
    },
    getIconName(section) {
      return section.title ? 'external-link' : 'download';
    },
  },
  externalLinkTooltipText: __('This link points to external content'),
  downloadTooltipText: __('Download'),
};
</script>

<template>
  <div>
    <gl-button
      data-testid="accordion-button"
      variant="link"
      class="!gl-text-default"
      button-text-classes="gl-heading-5"
      @click="toggleAssetsExpansion"
    >
      <gl-icon
        name="chevron-right"
        class="gl-transition-all"
        :class="{ 'gl-rotate-90': isAssetsExpanded }"
      />
      {{ __('Assets') }}
      <gl-badge variant="neutral" class="gl-inline-block">{{ assets.count }}</gl-badge>
    </gl-button>
    <gl-collapse v-model="isAssetsExpanded">
      <div class="js-assets-list gl-pl-6 gl-pt-3">
        <template v-for="(section, index) in sections">
          <h5 v-if="section.title" :key="`section-header-${index}`" class="gl-mb-2">
            {{ section.title }}
          </h5>
          <ul :key="`section-body-${index}`" class="list-unstyled gl-m-0">
            <li v-for="link in section.links" :key="link.url" class="gl-flex">
              <gl-link
                :href="link.directAssetUrl || link.url"
                class="gl-flex gl-items-center gl-leading-24"
                data-testid="asset-link"
              >
                <gl-icon :name="section.iconName" class="gl-mr-2 gl-shrink-0 gl-flex-grow-0" />
                {{ link.name }}
                <gl-icon
                  v-gl-tooltip
                  :name="getIconName(section)"
                  :aria-label="getTooltipTitle(section)"
                  :title="getTooltipTitle(section)"
                  data-testid="external-link-indicator"
                  class="gl-ml-2 gl-shrink-0 gl-flex-grow-0"
                />
              </gl-link>
            </li>
          </ul>
        </template>
      </div>
    </gl-collapse>
  </div>
</template>
