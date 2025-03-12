<script>
import { GlIcon, GlLink, GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __ } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import Sorter from '../../core/sorter';
import ThResizable from '../common/th_resizable.vue';

export default {
  name: 'TablePresenter',
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
    GlSkeletonLoader,
    ThResizable,
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
    isPreview: {
      required: false,
      type: Boolean,
      default: false,
    },
  },
  data() {
    const items = this.data.nodes.slice();

    return {
      items,
      fields: this.config.fields,
      sorter: new Sorter(items),
      table: null,
    };
  },
  computed: {
    title() {
      return this.config.title || __('GLQL table');
    },
    docsPath() {
      return `${helpPagePath('user/glql/_index')}#glql-views`;
    },
  },
  async mounted() {
    await this.$nextTick();

    this.table = this.$refs.table;
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
    class="!gl-mt-5 gl-overflow-hidden"
    body-class="!gl-m-[-1px] !gl-p-0"
    footer-class="!gl-border-t-0"
  >
    <div class="gl-table-shadow">
      <table ref="table" class="!gl-my-0 gl-overflow-y-hidden">
        <thead class="gl-text-sm">
          <tr v-if="table">
            <th-resizable v-for="(field, fieldIndex) in fields" :key="field.key" :table="table">
              <div
                :data-testid="`column-${fieldIndex}`"
                class="gl-cursor-pointer"
                @click="sorter.sortBy(field.key)"
              >
                {{ field.label }}
                <gl-icon
                  v-if="sorter.options.fieldName === field.key"
                  :name="sorter.options.ascending ? 'arrow-up' : 'arrow-down'"
                />
              </div>
            </th-resizable>
          </tr>
        </thead>
        <tbody class="!gl-bg-subtle">
          <template v-if="isPreview">
            <tr v-for="i in 5" :key="i">
              <td v-for="field in fields" :key="field.key">
                <gl-skeleton-loader :width="120" :lines="1" />
              </td>
            </tr>
          </template>
          <template v-else-if="items.length">
            <tr
              v-for="(item, itemIndex) in items"
              :key="item.id"
              :data-testid="`table-row-${itemIndex}`"
            >
              <td v-for="field in fields" :key="field.key">
                <component :is="presenter.forField(item, field.key)" />
              </td>
            </tr>
          </template>
          <tr v-else-if="!items.length">
            <td :colspan="fields.length" class="gl-text-center">
              {{ __('No data found for this query') }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>

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
