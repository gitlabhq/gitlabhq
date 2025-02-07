<script>
import { GlIcon, GlIntersperse, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __ } from '~/locale';

export default {
  name: 'ListPresenter',
  components: {
    GlIcon,
    GlIntersperse,
    GlLink,
    GlSprintf,
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
  },
  computed: {
    items() {
      return this.data.nodes || [];
    },
    fields() {
      return this.config.fields;
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
  <div class="gl-mb-4">
    <component :is="listType" class="!gl-mb-1" data-testid="list">
      <li
        v-for="(item, itemIndex) in items"
        :key="itemIndex"
        :data-testid="`list-item-${itemIndex}`"
      >
        <gl-intersperse separator=" · ">
          <span v-for="field in fields" :key="field.key">
            <component :is="presenter.forField(item, field.key)" />
          </span>
        </gl-intersperse>
      </li>
      <div v-if="!items.length" :dismissible="false" variant="tip" class="!gl-my-2">
        {{ __('No data found for this query') }}
      </div>
    </component>
    <div
      class="gl-mt-3 gl-flex gl-items-center gl-gap-1 gl-text-sm gl-text-subtle"
      data-testid="footer"
    >
      <gl-icon class="gl-mb-1 gl-mr-1" :size="12" name="tanuki" />
      <gl-sprintf :message="$options.i18n.generatedMessage">
        <template #link="{ content }">
          <gl-link :href="docsPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </div>
  </div>
</template>
