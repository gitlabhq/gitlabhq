<script>
import LoadingStateListItem from './loading_state_list_item.vue';

export default {
  name: 'LoadingStateList',
  components: {
    LoadingStateListItem,
  },
  props: {
    listLength: {
      type: Number,
      required: false,
      default: 5,
    },
    leftLinesCount: {
      type: Number,
      required: false,
      default: 2,
    },
    rightLinesCount: {
      type: Number,
      required: false,
      default: 2,
    },
  },
};
</script>

<template>
  <ul class="gl-m-0 gl-list-none gl-p-0">
    <li v-for="n in listLength" :key="n" class="gl-border-b gl-p-5">
      <loading-state-list-item
        :left-lines-count="leftLinesCount"
        :right-lines-count="rightLinesCount"
      />
    </li>
  </ul>
</template>
