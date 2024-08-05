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
      type: [String, Number],
      required: false,
      default: '',
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
  computed: {
    displayedCount() {
      return this.icon && !this.count ? '0' : this.count;
    },
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
    <div ref="crudComponent" class="crud gl-border gl-rounded-base gl-border-default gl-bg-subtle">
      <header
        class="gl-border-b gl-flex gl-flex-wrap gl-justify-between gl-gap-x-5 gl-gap-y-2 gl-rounded-t-base gl-border-default gl-bg-default gl-px-5 gl-py-4"
      >
        <div class="gl-flex gl-flex-col gl-self-center">
          <h2
            class="gl-m-0 gl-inline-flex gl-gap-3 gl-text-base gl-font-bold gl-leading-24"
            data-testid="crud-title"
          >
            {{ title }}
            <span
              v-if="displayedCount || $scopedSlots.count"
              class="gl-inline-flex gl-items-center gl-gap-2 gl-text-sm gl-text-subtle"
              data-testid="crud-count"
            >
              <slot v-if="$scopedSlots.count" name="count"></slot>
              <template v-else>
                <gl-icon v-if="icon" :name="icon" data-testid="crud-icon" />
                {{ displayedCount }}
              </template>
            </span>
          </h2>
          <p
            v-if="description || $scopedSlots.description"
            class="gl-mb-0 gl-mt-1 gl-text-sm gl-text-subtle"
            data-testid="crud-description"
          >
            <slot v-if="$scopedSlots.description" name="description"></slot>
            <template v-else>{{ description }}</template>
          </p>
        </div>
        <div class="gl-flex gl-items-baseline gl-gap-3" data-testid="crud-actions">
          <gl-button
            v-if="toggleText && !isFormVisible"
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
        class="gl-border-b gl-border-default gl-bg-default gl-p-5 gl-pt-4"
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

        <div
          v-if="$scopedSlots.pagination"
          class="gl-flex gl-justify-center gl-p-5 gl-border-t"
          data-testid="crud-pagination"
        >
          <slot name="pagination"></slot>
        </div>
      </div>

      <footer
        v-if="$scopedSlots.footer"
        class="gl-border-t gl-rounded-b-base gl-border-default gl-bg-default gl-px-5 gl-py-4"
        data-testid="crud-footer"
      >
        <slot name="footer"></slot>
      </footer>
    </div>
  </section>
</template>
