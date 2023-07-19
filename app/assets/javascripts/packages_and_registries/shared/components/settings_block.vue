<template>
  <section class="settings-section">
    <div class="settings-sticky-header">
      <div class="settings-sticky-header-inner">
        <h4 class="gl-my-0">
          <slot name="title"></slot>
        </h4>
      </div>
    </div>
    <p class="gl-text-secondary">
      <slot name="description"></slot>
    </p>
    <slot></slot>
  </section>
</template>
