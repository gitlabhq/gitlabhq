<script>
export default {
  props: {
    commitRef: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
  },
  computed: {
    parentRoute() {
      const splitArray = this.path.split('/');
      splitArray.pop();

      return { path: `/tree/${this.commitRef}/${splitArray.join('/')}` };
    },
  },
  methods: {
    clickRow() {
      this.$router.push(this.parentRoute);
    },
  },
};
</script>

<template>
  <tr class="tree-item">
    <td colspan="3" class="tree-item-file-name" @click.self="clickRow">
      <router-link :to="parentRoute" :aria-label="__('Go to parent')">
        ..
      </router-link>
    </td>
  </tr>
</template>
