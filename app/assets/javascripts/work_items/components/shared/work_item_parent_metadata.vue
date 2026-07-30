<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import { uniqueId } from 'lodash-es';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { titleInLinkSafeHtmlConfig } from '~/lib/dompurify';
import WorkItemPopover from '~/issuable/popover/components/work_item_popover.vue';

export default {
  name: 'WorkItemParentMetadata',
  components: {
    GlIcon,
    GlLink,
    WorkItemPopover,
  },
  directives: {
    SafeHtml,
  },
  titleInLinkSafeHtmlConfig,
  props: {
    parent: {
      type: Object,
      required: true,
    },
    iconSize: {
      type: Number,
      required: false,
      default: 16,
    },
  },
  data() {
    return {
      linkId: uniqueId('work-item-parent-metadata-link-'),
    };
  },
  computed: {
    parentWebUrl() {
      return this.parent?.webUrl;
    },
    parentTitle() {
      return this.parent?.title;
    },
    parentTitleHtml() {
      return this.parent?.titleHtml;
    },
    parentIid() {
      return this.parent?.iid || '';
    },
    parentNamespace() {
      return this.parent?.namespace?.fullPath || '';
    },
  },
};
</script>

<template>
  <div
    :id="linkId"
    class="gl-flex gl-cursor-pointer gl-items-center gl-gap-2 hover:gl-underline focus-visible:gl-no-underline active:gl-no-underline"
  >
    <gl-icon name="work-item-parent" :size="iconSize" class="gl-shrink-0" variant="subtle" />
    <gl-link
      data-testid="work-item-parent-metadata-link"
      class="gl-inline-block gl-max-w-18 gl-truncate gl-align-top !gl-text-subtle gl-no-underline hover:!gl-text-subtle hover:gl-no-underline"
      :href="parentWebUrl"
      @click.stop
    >
      <span v-safe-html:[$options.titleInLinkSafeHtmlConfig]="parentTitleHtml"></span>
    </gl-link>
    <work-item-popover
      :cached-title="parentTitle"
      :iid="parentIid"
      :namespace-path="parentNamespace"
      :target="linkId"
    >
      <template #header>
        <div class="gl-rounded-t-lg gl-bg-strong gl-px-4 gl-py-3">
          {{ __('Parent') }}
        </div>
      </template>
    </work-item-popover>
  </div>
</template>
