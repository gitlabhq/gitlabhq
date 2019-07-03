<script>
export default {
  name: 'RegistrySvgMessage',
  props: {
    id: {
      type: String,
      required: true,
    },
    svgPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div :id="id" class="empty-state container-message mw-70p">
    <div class="svg-content">
      <img :src="svgPath" class="flex-align-self-center" />
    </div>
    <slot></slot>
  </div>
</template>
