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
  <tr v-once @click="clickRow">
    <td colspan="3" class="tree-item-file-name">
      <router-link :to="parentRoute" :aria-label="__('Go to parent')">
        ..
      </router-link>
    </td>
  </tr>
</template>
