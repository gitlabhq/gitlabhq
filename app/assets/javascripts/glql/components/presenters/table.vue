<script>
import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __ } from '~/locale';
import Sorter from '../../core/sorter';
import ThResizable from '../common/th_resizable.vue';

export default {
  name: 'TablePresenter',
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
    ThResizable,
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
  <div class="!gl-my-4">
    <table ref="table" class="!gl-mb-2 !gl-mt-0 gl-overflow-y-hidden">
      <thead>
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
      <tbody>
        <tr
          v-for="(item, itemIndex) in items"
          :key="item.id"
          :data-testid="`table-row-${itemIndex}`"
        >
          <td v-for="field in fields" :key="field.key">
            <component :is="presenter.forField(item, field.key)" />
          </td>
        </tr>
        <tr v-if="!items.length">
          <td :colspan="fields.length" class="gl-text-center">
            {{ __('No data found for this query') }}
          </td>
        </tr>
      </tbody>
    </table>
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
