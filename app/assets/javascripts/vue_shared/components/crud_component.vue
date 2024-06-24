<script>
import { GlButton, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlIcon,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: false,
      default: null,
    },
    count: {
      type: Number,
      required: false,
      default: null,
    },
    icon: {
      type: String,
      required: false,
      default: null,
    },
    toggleText: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      isFormVisible: false,
    };
  },
  methods: {
    toggleForm() {
      this.isFormVisible = !this.isFormVisible;
    },
    showForm() {
      this.isFormVisible = true;
    },
    hideForm() {
      this.isFormVisible = false;
    },
  },
};
</script>

<template>
  <section>
    <div ref="crudComponent" class="crud gl-bg-subtle gl-border gl-border-default gl-rounded-base">
      <header
        class="gl-flex gl-flex-wrap gl-justify-between gl-gap-x-5 gl-gap-y-2 gl-px-5 gl-py-4 gl-bg-default gl-border-b gl-border-default gl-rounded-t-base"
      >
        <div class="gl-flex gl-flex-col gl-self-center">
          <h2
            class="gl-text-base gl-font-bold gl-leading-24 gl-inline-flex gl-gap-3 gl-m-0"
            data-testid="crud-title"
          >
            {{ title }}
            <span
              v-if="count"
              class="gl-inline-flex gl-items-center gl-gap-2 gl-text-sm gl-text-secondary"
              data-testid="crud-count"
            >
              <gl-icon v-if="icon" :name="icon" />
              {{ count }}
            </span>
          </h2>
          <p
            v-if="description || $scopedSlots.description"
            class="gl-text-sm gl-text-secondary gl-mt-1 gl-mb-0"
            data-testid="crud-description"
          >
            <slot v-if="$scopedSlots.description" name="description"></slot>
            <template v-else>{{ description }}</template>
          </p>
        </div>
        <div class="gl-flex gl-gap-3 gl-items-baseline" data-testid="crud-actions">
          <gl-button
            v-if="toggleText"
            size="small"
            data-testid="crud-form-toggle"
            @click="toggleForm"
            >{{ toggleText }}</gl-button
          >
          <slot name="actions"></slot>
        </div>
      </header>

      <div
        v-if="$scopedSlots.form && isFormVisible"
        class="gl-p-5 gl-pt-4 gl-bg-default gl-border-b gl-border-default"
        data-testid="crud-form"
      >
        <slot name="form"></slot>
      </div>

      <div
        class="crud-body gl-mx-5 gl-my-4"
        :class="{ 'gl-rounded-b-base': !$scopedSlots.footer }"
        data-testid="crud-body"
      >
        <slot></slot>
      </div>

      <footer
        v-if="$scopedSlots.footer"
        class="gl-px-5 gl-py-4 gl-bg-default gl-border-t gl-border-default gl-rounded-b-base"
        data-testid="crud-footer"
      >
        <slot name="footer"></slot>
      </footer>
    </div>
    <div v-if="$scopedSlots.pagination" class="gl-mt-5" data-testid="crud-pagination">
      <slot name="pagination"></slot>
    </div>
  </section>
</template>
