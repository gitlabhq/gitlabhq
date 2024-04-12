<template>
  <section class="settings-section">
    <div class="settings-sticky-header">
      <div class="settings-sticky-header-inner">
        <h3 class="gl-heading-3 gl-mb-0!">
          <slot name="title"></slot>
        </h3>
      </div>
    </div>
    <p class="gl-text-secondary">
      <slot name="description"></slot>
    </p>
    <slot></slot>
  </section>
</template>
