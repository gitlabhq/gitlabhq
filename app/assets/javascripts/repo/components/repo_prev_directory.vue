<script>
  import { mapGetters, mapState, mapActions } from 'vuex';

  export default {
    computed: {
      ...mapState([
        'parentTreeUrl',
      ]),
      ...mapGetters([
        'isCollapsed',
      ]),
      colSpanCondition() {
        return this.isCollapsed ? undefined : 3;
      },
    },
    methods: {
      ...mapActions([
        'getTreeData',
      ]),
    },
  };
</script>

<template>
  <tr class="file prev-directory">
    <td
      :colspan="colSpanCondition"
      class="table-cell"
      @click.prevent="getTreeData({ endpoint: parentTreeUrl })"
    >
      <a :href="parentTreeUrl">...</a>
    </td>
  </tr>
</template>
