<script>
import { GlIcon, GlLink, GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import { __ } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import Sorter from '../../core/sorter';
import ThResizable from '../common/th_resizable.vue';
import GlqlFooter from '../common/footer.vue';
import GlqlActions from '../common/actions.vue';

export default {
  name: 'TablePresenter',
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
    GlSkeletonLoader,
    GlqlFooter,
    ThResizable,
    CrudComponent,
    GlqlActions,
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
      isCollapsed: false,
    };
  },
  computed: {
    title() {
      return this.config.title || __('GLQL table');
    },
    showCopyContentsAction() {
      return Boolean(this.items.length) && !this.isCollapsed && !this.isPreview;
    },
    showEmptyState() {
      return !this.items.length && !this.isPreview;
    },
  },
  async mounted() {
    await this.$nextTick();

    this.table = this.$refs.table;
  },
};
</script>
<template>
  <crud-component
    :anchor-id="queryKey"
    :title="title"
    :description="config.description"
    :count="items.length"
    is-collapsible
    persist-collapsed-state
    class="!gl-mt-5 gl-overflow-hidden"
    :body-class="{ '!gl-m-[-1px] !gl-p-0': items.length || isPreview }"
    footer-class="!gl-border-t-0"
    @collapsed="isCollapsed = true"
    @expanded="isCollapsed = false"
  >
    <template #actions>
      <glql-actions :show-copy-contents="showCopyContentsAction" :modal-title="title" />
    </template>
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
        </tbody>
      </table>
    </div>

    <template v-if="showEmptyState" #empty>
      {{ __('No data found for this query.') }}
    </template>

    <template #footer><glql-footer /></template>
  </crud-component>
</template>
