<template>
  <div>
    <div v-for="index in 10" :key="index" class="gl-flex gl-items-center gl-gap-3">
      <div
        class="gl-animate-skeleton-loader gl-my-3 gl-h-7 gl-w-7 gl-shrink-0 gl-rounded-full"
      ></div>
      <div
        class="gl-animate-skeleton-loader gl-my-3 gl-h-5 gl-w-75 gl-max-w-full gl-rounded-base"
      ></div>
    </div>
  </div>
</template>
