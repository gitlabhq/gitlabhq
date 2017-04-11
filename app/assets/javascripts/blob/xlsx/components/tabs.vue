<template>
  <ul class="nav nav-tabs prepend-top-default">
    <li
      class="prepend-left-10"
      v-for="name in sheetNames"
      :class="{ active: name === currentSheetName }">
      <a
        :href="getTabPath(name)"
        @click="changeSheet(name)">
        {{ name }}
      </a>
    </li>
  </ul>
</template>

<script>
import eventHub from '../eventhub';

export default {
  name: 'XLSXTabs',
  props: {
    currentSheetName: {
      type: String,
      required: true,
    },
    sheetNames: {
      type: Array,
      required: true,
    },
  },
  methods: {
    changeSheet(name) {
      eventHub.$emit('update-sheet', name);
    },
    getTabPath(name) {
      return `#${encodeURIComponent(name)}`;
    },
  },
};
</script>
