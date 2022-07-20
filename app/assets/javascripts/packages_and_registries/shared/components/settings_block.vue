<template>
  <section class="settings gl-py-7">
    <div class="gl-lg-display-flex">
      <div class="gl-lg-w-half gl-pr-10">
        <h4>
          <slot name="title"></slot>
        </h4>
        <p>
          <slot name="description"></slot>
        </p>
      </div>
      <div class="gl-lg-w-half gl-pt-3">
        <slot></slot>
      </div>
    </div>
  </section>
</template>
