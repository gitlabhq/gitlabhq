<template>
  <div>
    <template v-for="count in 5"
      ><span :key="count">{{ count }}</span></template
    >
  </div>
</template>
