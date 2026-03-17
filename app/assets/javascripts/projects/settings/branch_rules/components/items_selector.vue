<script>
import ListSelector from '~/vue_shared/components/list_selector/index.vue';
import { GROUPS_TYPE } from '~/vue_shared/components/list_selector/constants';

export default {
  name: 'ItemsSelector',
  GROUPS_TYPE,
  components: {
    ListSelector,
  },
  inject: {
    projectPath: {
      default: '',
    },
    projectId: {
      default: null,
    },
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
    usersOptions: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  emits: ['change'],
  data() {
    return {
      selectedItems: [],
    };
  },
  computed: {
    isGroupType() {
      return this.type === GROUPS_TYPE;
    },
  },
  beforeMount() {
    this.selectedItems = [...this.items];
  },
  methods: {
    handleSelect(item) {
      this.selectedItems.push(item);
      this.$emit('change', this.selectedItems);
    },
    handleDelete(id) {
      const index = this.selectedItems.findIndex((item) => item.id === id);
      this.selectedItems.splice(index, 1);
      this.$emit('change', this.selectedItems);
    },
  },
};
</script>

<template>
  <div>
    <list-selector
      :type="type"
      class="gl-mt-5 !gl-p-0"
      :disable-namespace-dropdown="isGroupType"
      :is-groups-with-project-access="isGroupType"
      :project-path="projectPath"
      :project-id="projectId"
      :selected-items="selectedItems"
      :users-query-options="usersOptions"
      @select="handleSelect"
      @delete="handleDelete"
    />
  </div>
</template>
