<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: { GlIcon },
  contentClass: 'gl-ml-5 gl-text-subtle',
  listClass: 'gl-mb-0 gl-ml-2 gl-pl-7 gl-text-subtle',
};
</script>

<template>
  <div class="gl-flex gl-flex-col gl-gap-4">
    <section>
      <gl-icon name="admin" /> <span>{{ __('Admin area') }}</span>
      <div v-if="$scopedSlots['admin-content']" :class="$options.contentClass">
        <slot name="admin-content"></slot>
      </div>
      <ul v-if="$scopedSlots['admin-list']" :class="$options.listClass">
        <slot name="admin-list"></slot>
      </ul>
    </section>

    <section>
      <gl-icon name="group" /> <span>{{ __('Groups and projects') }}</span>
      <div v-if="$scopedSlots['group-content']" :class="$options.contentClass">
        <slot name="group-content"></slot>
      </div>
      <ul v-if="$scopedSlots['group-list']" :class="$options.listClass">
        <slot name="group-list"></slot>
      </ul>
    </section>

    <section>
      <gl-icon name="settings" /> <span>{{ s__('AdminUsers|Groups and project settings') }}</span>
      <div v-if="$scopedSlots['settings-content']" :class="$options.contentClass">
        <slot name="settings-content"></slot>
      </div>
      <ul v-if="$scopedSlots['settings-list']" :class="$options.listClass">
        <slot name="settings-list"></slot>
      </ul>
    </section>
  </div>
</template>
