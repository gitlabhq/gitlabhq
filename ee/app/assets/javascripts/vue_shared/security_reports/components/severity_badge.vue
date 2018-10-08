<script>
export default {
  name: 'SeverityBadge',
  props: {
    severity: {
      type: String,
      required: true,
    },
  },
  computed: {
    className() {
      return `severity-badge-${this.severity}`;
    },
  },
};
</script>

<template>
  <div
    class="severity-badge"
    :class="className"
  >{{ severity }}</div>
</template>

<style>
.severity-badge {
  background-color: #f2f2f2;
  border-radius: 0.3em;
  color: #505050;
  display: inline-block;
  font-size: 0.9em;
  font-weight: bold;
  line-height: 1em;
  padding: 0.6em 0.4em 0.4em;
  text-transform: uppercase;
}

.severity-badge-critical {
  background-color: #fae5e1;
  color: #c0341e;
}

.severity-badge-high {
  background-color: #fff1de;
  color: #de7e00;
}

.severity-badge-medium {
  background-color: #ede8fb;
  color: #6d49cb;
}

.severity-badge-unknown {
  background-color: #ffffff;
  border: 1px solid;
  color: #707070;
}
</style>
