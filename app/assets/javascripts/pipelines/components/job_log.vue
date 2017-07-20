<script>
  export default {
    name: 'jobLog',
    props: {
      log: {
        type: Array,
        required: true,
      },
    },
    methods: {
      getLineLink(number) {
        return `#L${number}`
      }
    }
  };
</script>
<template>
  <ul class="trace-log">
    <li class="line-container" v-for="(line, index) in log">
      <ul>
        <li class="number"><a :href="getLineLink(index)">{{index}}</a></li>
        <li class="code" v-html="line"></li>
      </ul>
    </li>
  </ul>
</template>
