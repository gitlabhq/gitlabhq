<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { reportToSentry } from '~/ci/utils';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import {
  INSTRUMENT_TODO_ITEM_CLICK,
  TAB_ALL,
  TODO_STATE_DONE,
  TODO_STATE_PENDING,
} from '../constants';
import markAsDoneMutation from './mutations/mark_as_done.mutation.graphql';
import markAsPendingMutation from './mutations/mark_as_pending.mutation.graphql';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  inject: ['currentTab'],
  props: {
    todo: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    isDone() {
      return this.todo.state === TODO_STATE_DONE;
    },
    isPending() {
      return this.todo.state === TODO_STATE_PENDING;
    },
    tooltipTitle() {
      // Setting this to null while loading, combined with keeping the
      // loading state till the item gets removed, prevents the tooltip
      // text changing with the item state before the item gets removed.
      if (this.isLoading) return null;

      return this.isDone ? this.$options.i18n.markAsPending : this.$options.i18n.markAsDone;
    },
  },
  methods: {
    showMarkAsDoneError() {
      const toastProps = {
        text: s__('Todos|Mark as done failed. Try again later.'),
        variant: 'danger',
      };

      this.$toast.show(toastProps.text, {
        variant: toastProps.variant,
      });
    },
    showMarkAsPendingError() {
      const toastProps = {
        text: s__('Todos|Failed adding todo. Try again later.'),
        variant: 'danger',
      };

      this.$toast.show(toastProps.text, {
        variant: toastProps.variant,
      });
    },
    async toggleStatus() {
      this.track(INSTRUMENT_TODO_ITEM_CLICK, {
        label: this.isDone ? 'mark_pending' : 'mark_done',
      });
      const mutation = this.isDone ? markAsPendingMutation : markAsDoneMutation;
      const showError = this.isDone ? this.showMarkAsPendingError : this.showMarkAsDoneError;

      try {
        this.isLoading = true;

        const { data } = await this.$apollo.mutate({
          mutation,
          variables: {
            todoId: this.todo.id,
          },
        });

        if (data.errors?.length > 0) {
          reportToSentry(this.$options.name, new Error(data.errors.join(', ')));
          showError();
        } else {
          this.$emit('change', this.todo.id, this.isDone);
        }
      } catch (failure) {
        reportToSentry(this.$options.name, failure);
        showError();
        this.isLoading = false;
      } finally {
        // Only stop loading spinner when on "All" tab.
        // On the other tabs (Pending/Done) we want the loading to continue
        // until the todos query finished, removing this item from the list.
        // This way we hide the state change, which would otherwise update
        // the button's icon before it gets removed.
        if (this.currentTab === TAB_ALL) {
          this.isLoading = false;
        }
      }
    },
  },
  i18n: {
    markAsPending: s__('Todos|Undo'),
    markAsDone: s__('Todos|Mark as done'),
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.hover
    :icon="isDone ? 'redo' : 'check'"
    :loading="isLoading"
    :aria-label="isDone ? $options.i18n.markAsPending : $options.i18n.markAsDone"
    :title="tooltipTitle"
    @click.prevent="toggleStatus"
  />
</template>
