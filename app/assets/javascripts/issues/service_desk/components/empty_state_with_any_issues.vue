<script>
import { GlEmptyState } from '@gitlab/ui';
import {
  noSearchResultsTitle,
  noSearchResultsDescription,
  infoBannerUserNote,
  noOpenIssuesTitle,
  noClosedIssuesTitle,
} from '../constants';

export default {
  i18n: {
    noSearchResultsTitle,
    noSearchResultsDescription,
    infoBannerUserNote,
    noOpenIssuesTitle,
    noClosedIssuesTitle,
  },
  components: {
    GlEmptyState,
  },
  inject: ['emptyStateSvgPath'],
  props: {
    hasSearch: {
      type: Boolean,
      required: true,
    },
    isOpenTab: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    content() {
      if (this.hasSearch) {
        return {
          title: noSearchResultsTitle,
          description: noSearchResultsDescription,
          svgHeight: 150,
        };
      }
      if (this.isOpenTab) {
        return { title: noOpenIssuesTitle, description: infoBannerUserNote };
      }

      return { title: noClosedIssuesTitle, svgHeight: 150 };
    },
  },
};
</script>

<template>
  <gl-empty-state
    :description="content.description"
    :title="content.title"
    :svg-path="emptyStateSvgPath"
    :svg-height="content.svgHeight"
    data-testid="issuable-empty-state"
  />
</template>
