<script>
import { GlBadge, GlPopover, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  components: {
    GlBadge,
    GlPopover,
    GlLink,
    GlSprintf,
  },
  props: {
    isPublished: {
      type: Boolean,
      required: false,
      default: false,
    },
    exploreCatalogPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  ciCatalogBadgePopoverHelpLink: helpPagePath('ci/components/_index.md', {
    anchor: 'publish-a-new-release',
  }),
};
</script>

<template>
  <gl-badge
    v-if="isPublished"
    icon="catalog-checkmark"
    variant="info"
    data-testid="ci-catalog-badge"
    :href="exploreCatalogPath"
    >{{ s__('CiCatalog|CI/CD Catalog') }}</gl-badge
  >
  <button
    v-else
    id="unpublished-catalog-badge"
    class="gl-ml-1 gl-inline-block gl-rounded-full gl-border-0 gl-bg-transparent gl-p-0 gl-leading-0 focus-visible:gl-focus-inset"
  >
    <gl-badge icon="catalog-checkmark" variant="warning" data-testid="ci-catalog-badge-unpublished"
      >{{ s__('CiCatalog|CI/CD Catalog (unpublished)') }}
      <gl-popover
        target="unpublished-catalog-badge"
        container="unpublished-catalog-badge"
        :title="s__('CiCatalog|Catalog project (unpublished)')"
      >
        <gl-sprintf
          :message="
            s__(
              'CiCatalog|This project is set as a Catalog project, but has not yet been published. Publish this project to the Catalog to make it available. %{linkStart}Learn how to publish a new release%{linkEnd}',
            )
          "
        >
          <template #link="{ content }">
            <gl-link
              :href="$options.ciCatalogBadgePopoverHelpLink"
              target="_blank"
              class="gl-mt-3 gl-block"
              >{{ content }}</gl-link
            >
          </template>
        </gl-sprintf>
      </gl-popover>
    </gl-badge>
  </button>
</template>
