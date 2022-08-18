<template>
  <section class="settings gl-py-7">
    <div class="gl-lg-display-flex gl-gap-6">
      <div class="gl-lg-w-40p gl-pr-10 gl-flex-shrink-0">
        <h4>
          <slot name="title"></slot>
        </h4>
        <p>
          <slot name="description"></slot>
        </p>
      </div>
      <div class="gl-pt-3 gl-flex-grow-1">
        <slot></slot>
      </div>
    </div>
  </section>
</template>
