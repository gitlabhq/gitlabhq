<template>
  <div class="gl-border-b gl-flex gl-flex-col gl-py-5 @sm/panel:gl-flex-row">
    <h1 class="gl-heading-2 gl-flex-1 @sm/panel:gl-mb-0" data-testid="work-item-list-title">
      {{ s__('WorkItem|Work items') }}
    </h1>
    <slot></slot>
  </div>
</template>
