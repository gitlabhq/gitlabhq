<script>
  import tooltip from '~/vue_shared/directives/tooltip';
  import icon from '~/vue_shared/components/icon.vue';

  export default {
    components: {
      icon,
    },
    directives: {
      tooltip,
    },
    props: {
      title: {
        type: String,
        required: false,
        default: '',
      },
      cssClass: {
        type: String,
        required: false,
        default: '',
      },
      iconName: {
        type: String,
        required: true,
      },
      tooltipPlacement: {
        type: String,
        required: false,
        default: 'bottom',
      },
      /**
       * value could either be number or string
       * as `memberCount` is always passed as string
       * while `subgroupCount` & `projectCount`
       * are always number
       */
      value: {
        type: [Number, String],
        required: false,
        default: '',
      },
    },
    computed: {
      isValuePresent() {
        return this.value !== '';
      },
    },
  };
</script>

<template>
  <span
    v-tooltip
    data-container="body"
    :data-placement="tooltipPlacement"
    :class="cssClass"
    :title="title"
  >
    <icon :name="iconName" />
    <span
      v-if="isValuePresent"
      class="stat-value"
    >
      {{ value }}
    </span>
  </span>
</template>
