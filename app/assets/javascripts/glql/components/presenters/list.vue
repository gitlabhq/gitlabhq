<script>
import { GlIcon, GlIntersperse, GlLink, GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import { __ } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import GlqlFooter from '../common/footer.vue';
import GlqlActions from '../common/actions.vue';

export default {
  name: 'ListPresenter',
  components: {
    GlIcon,
    GlIntersperse,
    GlLink,
    GlSprintf,
    GlSkeletonLoader,
    CrudComponent,
    GlqlActions,
    GlqlFooter,
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
    isPreview: {
      required: false,
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      isCollapsed: false,
    };
  },
  computed: {
    title() {
      return this.config.title || __('GLQL list');
    },
    items() {
      return this.data.nodes || [];
    },
    fields() {
      return this.config.fields?.filter((item) => item.key !== 'title');
    },
    showCopyContentsAction() {
      return Boolean(this.items.length) && !this.isCollapsed && !this.isPreview;
    },
    showEmptyState() {
      return !this.items.length && !this.isPreview;
    },
  },
};
</script>
<template>
  <crud-component
    :anchor-id="queryKey"
    :title="title"
    :description="config.description"
    :count="items.length"
    persist-collapsed-state
    is-collapsible
    class="!gl-mt-5"
    @collapsed="isCollapsed = true"
    @expanded="isCollapsed = false"
  >
    <template #actions>
      <glql-actions :show-copy-contents="showCopyContentsAction" :modal-title="title" />
    </template>
    <component :is="listType" class="content-list !gl-mb-0" data-testid="list">
      <template v-if="isPreview">
        <li
          v-for="i in 5"
          :key="i"
          class="gl-py-3"
          :class="{
            'gl-border-b gl-border-b-section': i !== 4,
            '!gl-ml-0': config.type == 'list',
          }"
        >
          <gl-skeleton-loader :width="400" :lines="1" />
        </li>
      </template>
      <template v-else-if="items.length">
        <li
          v-for="(item, itemIndex) in items"
          :key="itemIndex"
          class="gl-py-3"
          :class="{
            'gl-border-b gl-border-b-section': itemIndex !== items.length - 1,
            '!gl-ml-0': config.type == 'list',
          }"
          :data-testid="`list-item-${itemIndex}`"
        >
          <h3 class="!gl-heading-5 !gl-mb-1">
            <component :is="presenter.forField(item, 'title')" />
          </h3>
          <gl-intersperse separator=" · ">
            <span v-for="field in fields" :key="field.key">
              <component :is="presenter.forField(item, field.key)" />
            </span>
          </gl-intersperse>
        </li>
      </template>
    </component>

    <template v-if="showEmptyState" #empty>
      {{ __('No data found for this query.') }}
    </template>

    <template #footer><glql-footer /></template>
  </crud-component>
</template>
