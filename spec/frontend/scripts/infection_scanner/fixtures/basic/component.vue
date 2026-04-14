<script>
import { helper } from './utils';

export default {
  name: 'TestComponent',
  data() {
    return { msg: helper() };
  },
};
</script>

<template>
  <div>{{ msg }}</div>
</template>
