<script>
import { GlIcon, GlIntersperse, GlLink, GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __ } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';

export default {
  name: 'ListPresenter',
  components: {
    GlIcon,
    GlIntersperse,
    GlLink,
    GlSprintf,
    GlSkeletonLoader,
    CrudComponent,
  },
  inject: ['presenter'],
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
    docsPath() {
      return `${helpPagePath('user/glql/_index')}#glql-views`;
    },
  },
  i18n: {
    generatedMessage: __('%{linkStart}View%{linkEnd} powered by GLQL'),
  },
};
</script>
<template>
  <crud-component
    :title="title"
    :description="config.description"
    :count="items.length"
    is-collapsible
    class="!gl-mt-5"
  >
    <component :is="listType" class="content-list !gl-mb-0" data-testid="list">
      <template v-if="isPreview">
        <li v-for="i in 5" :key="i">
          <gl-skeleton-loader :width="400" :lines="1" />
        </li>
      </template>
      <template v-else-if="items.length">
        <li
          v-for="(item, itemIndex) in items"
          :key="itemIndex"
          class="gl-py-3"
          :class="{ 'gl-border-b gl-border-b-section': itemIndex !== items.length - 1 }"
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

    <template v-if="!items.length && !isPreview" #empty>
      {{ __('No data found for this query.') }}
    </template>

    <template #footer>
      <div class="gl-flex gl-items-center gl-gap-1 gl-text-sm gl-text-subtle" data-testid="footer">
        <gl-icon class="gl-mb-1 gl-mr-1" :size="12" name="tanuki" />
        <gl-sprintf :message="$options.i18n.generatedMessage">
          <template #link="{ content }">
            <gl-link :href="docsPath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </div>
    </template>
  </crud-component>
</template>
