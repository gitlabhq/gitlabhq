<template>
  <section class="settings gl-py-7">
    <div class="row">
      <div class="col-lg-4">
        <h4>
          <slot name="title"></slot>
        </h4>
        <p>
          <slot name="description"></slot>
        </p>
      </div>
      <div class="col-lg-8 gl-pt-3">
        <slot></slot>
      </div>
    </div>
  </section>
</template>
