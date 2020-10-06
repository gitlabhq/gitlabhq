<script>
import { GlTooltipDirective, GlLink, GlButton, GlCollapse, GlIcon, GlBadge } from '@gitlab/ui';
import { difference, get } from 'lodash';
import { ASSET_LINK_TYPE } from '../constants';
import { __, s__, sprintf } from '~/locale';

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
  props: {
    assets: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isAssetsExpanded: true,
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
          links: get(this.assets, 'sources', []).map(s => ({
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
      ].filter(section => section.links.length > 0);
    },
  },
  methods: {
    toggleAssetsExpansion() {
      this.isAssetsExpanded = !this.isAssetsExpanded;
    },
    linksForType(type) {
      return this.assets.links.filter(l => l.linkType === type);
    },
  },
  externalLinkTooltipText: __('This link points to external content'),
};
</script>

<template>
  <div class="card-text gl-mt-3">
    <gl-button
      data-testid="accordion-button"
      variant="link"
      class="gl-font-weight-bold"
      @click="toggleAssetsExpansion"
    >
      <gl-icon
        name="chevron-right"
        class="gl-transition-medium"
        :class="{ 'gl-rotate-90': isAssetsExpanded }"
      />
      {{ __('Assets') }}
      <gl-badge size="sm" variant="neutral" class="gl-display-inline-block">{{
        assets.count
      }}</gl-badge>
    </gl-button>
    <gl-collapse v-model="isAssetsExpanded">
      <div class="gl-pl-6 gl-pt-3 js-assets-list">
        <template v-for="(section, index) in sections">
          <h5 v-if="section.title" :key="`section-header-${index}`" class="gl-mb-2">
            {{ section.title }}
          </h5>
          <ul :key="`section-body-${index}`" class="list-unstyled gl-m-0">
            <li v-for="link in section.links" :key="link.url" class="gl-display-flex">
              <gl-link
                :href="link.directAssetUrl || link.url"
                class="gl-display-flex gl-align-items-center gl-line-height-24"
              >
                <gl-icon :name="section.iconName" class="gl-mr-2 gl-flex-shrink-0 gl-flex-grow-0" />
                {{ link.name }}
                <gl-icon
                  v-if="link.external"
                  v-gl-tooltip
                  name="external-link"
                  :aria-label="$options.externalLinkTooltipText"
                  :title="$options.externalLinkTooltipText"
                  data-testid="external-link-indicator"
                  class="gl-ml-2 gl-flex-shrink-0 gl-flex-grow-0 gl-text-gray-400"
                />
              </gl-link>
            </li>
          </ul>
        </template>
      </div>
    </gl-collapse>
  </div>
</template>
