<script>
import { GlIcon, GlLink, GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import { eventHubByKey } from '../../utils/event_hub_factory';
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
    showPreview: {
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
      eventHub: eventHubByKey(this.queryKey),
      isLoadingMore: false,
      pageSize: 5,
    };
  },
  mounted() {
    this.eventHub.$on('loadMore', (pageSize) => {
      this.pageSize = pageSize;
      this.isLoadingMore = true;
    });

    this.eventHub.$on('loadMoreComplete', (newData) => {
      this.items = newData.nodes.slice();
      this.sorter = this.sorter.clone(this.items);
      this.isLoadingMore = false;
    });

    this.eventHub.$on('loadMoreError', () => {
      this.isLoadingMore = false;
    });
  },
};
</script>
<template>
  <div class="gl-table-shadow">
    <table class="!gl-my-0 gl-overflow-y-hidden">
      <thead class="!gl-border-b !gl-border-section gl-text-sm">
        <tr>
          <th-resizable
            v-for="(field, fieldIndex) in fields"
            :key="field.key"
            class="gl-relative !gl-border-section !gl-bg-subtle !gl-p-0 !gl-text-subtle gl-text-subtle dark:!gl-bg-strong"
          >
            <div
              :data-testid="`column-${fieldIndex}`"
              class="gl-l-0 gl-r-0 gl-absolute gl-w-full gl-cursor-pointer gl-truncate gl-px-5 gl-py-3 gl-transition-colors hover:gl-bg-strong dark:hover:gl-bg-neutral-700"
              @click="sorter.sortBy(field.key)"
            >
              <gl-icon
                v-if="sorter.options.fieldName === field.key"
                :name="sorter.options.ascending ? 'arrow-up' : 'arrow-down'"
              />
              {{ field.label }}
            </div>
            <div class="gl-pointer-events-none gl-py-3">&nbsp;</div>
          </th-resizable>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="(item, itemIndex) in items"
          :key="item.id"
          :data-testid="`table-row-${itemIndex}`"
        >
          <td
            v-for="field in fields"
            :key="field.key"
            class="!gl-border-l-0 !gl-border-r-0 !gl-border-section gl-bg-subtle !gl-px-5 !gl-py-3 gl-transition-colors"
          >
            <!-- eslint-disable-next-line @gitlab/vue-no-new-non-primitive-in-template -->
            <component :is="presenter.forField(item, field.key)" />
          </td>
        </tr>
        <template v-if="showPreview || isLoadingMore">
          <tr v-for="i in pageSize" :key="i">
            <td
              v-for="field in fields"
              :key="field.key"
              class="!gl-border-l-0 !gl-border-r-0 !gl-border-t-0 !gl-border-section gl-bg-subtle !gl-px-5 !gl-py-3 gl-transition-colors"
            >
              <gl-skeleton-loader :width="60" :lines="1" :equal-width-lines="true" />
            </td>
          </tr>
        </template>
      </tbody>
    </table>
  </div>
</template>
