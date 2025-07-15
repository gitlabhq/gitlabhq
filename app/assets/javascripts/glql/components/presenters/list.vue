<script>
import { GlIcon, GlIntersperse, GlLink, GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import { eventHubByKey } from '../../utils/event_hub_factory';

export default {
  name: 'ListPresenter',
  components: {
    GlIcon,
    GlIntersperse,
    GlLink,
    GlSprintf,
    GlSkeletonLoader,
  },
  inject: ['presenter', 'queryKey'],
  props: {
    data: {
      required: true,
      type: Object,
      validator: ({ nodes }) => Array.isArray(nodes),
    },
    config: {
      required: true,
      type: Object,
      validator: ({ fields }) => Array.isArray(fields) && fields.length > 0,
    },
    listType: {
      required: false,
      type: String,
      default: 'ul',
      validator: (value) => ['ul', 'ol'].includes(value),
    },
    showPreview: {
      required: false,
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      eventHub: eventHubByKey(this.queryKey),
      isLoadingMore: false,
      pageSize: 5,
    };
  },
  computed: {
    items() {
      return this.data.nodes || [];
    },
    fields() {
      return this.config.fields?.filter((item) => item.key !== 'title');
    },
  },
  mounted() {
    this.eventHub.$on('loadMore', (pageSize) => {
      this.pageSize = pageSize;
      this.isLoadingMore = true;
    });

    this.eventHub.$on('loadMoreComplete', () => {
      this.isLoadingMore = false;
    });

    this.eventHub.$on('loadMoreError', () => {
      this.isLoadingMore = false;
    });
  },
};
</script>
<template>
  <component :is="listType" class="content-list !gl-mb-0" data-testid="list">
    <li
      v-for="(item, itemIndex) in items"
      :key="itemIndex"
      class="!gl-m-0 gl-list-inside !gl-px-5 !gl-py-3 gl-transition-background hover:gl-bg-strong dark:hover:gl-bg-neutral-700"
      :class="{
        'gl-border-b !gl-border-b-section': itemIndex !== items.length - 1 || isLoadingMore,
      }"
      :data-testid="`list-item-${itemIndex}`"
    >
      <div
        class="gl-str-truncated gl-inline-block gl-max-w-[calc(100%-40px)] gl-pl-2 gl-pt-1 gl-align-top"
      >
        <h3 class="!gl-heading-5 !gl-mb-1 gl-truncate">
          <component :is="presenter.forField(item, 'title')" />
        </h3>
        <div>
          <gl-intersperse separator=" · ">
            <span v-for="field in fields" :key="field.key">
              <component :is="presenter.forField(item, field.key)" />
            </span>
          </gl-intersperse>
        </div>
      </div>
    </li>
    <template v-if="showPreview || isLoadingMore">
      <li
        v-for="i in pageSize"
        :key="i"
        class="!gl-m-0 gl-list-inside !gl-px-5 !gl-py-3 gl-transition-background hover:gl-bg-strong dark:hover:gl-bg-neutral-700"
        :class="{ 'gl-border-b !gl-border-b-section': i !== pageSize }"
      >
        <div class="gl-inline-block gl-align-top">
          <gl-skeleton-loader :width="400" :lines="1" :equal-width-lines="true" />
        </div>
      </li>
    </template>
  </component>
</template>
