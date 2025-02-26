import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { INSTRUMENT_TODO_BULK_CLICK } from '~/todos/constants';
import { s__ } from '~/locale';
import Tracking from '~/tracking';

export const bulkMutationsMixin = {
  mixins: [Tracking.mixin()],
  methods: {
    async handleBulkMutation({
      mutation,
      variables,
      responseKey,
      trackingLabel,
      getMessage,
      undoMethod = null,
    }) {
      this.track(INSTRUMENT_TODO_BULK_CLICK, { label: trackingLabel });

      try {
        const resp = await this.$apollo.mutate({
          mutation,
          variables,
        });

        if (resp.data.errors?.length > 0) {
          throw new Error(resp.data.errors.join(', '));
        }

        const data = resp.data[responseKey];

        if (data.todos) {
          const todoIDs = data.todos.map((todo) => todo.id);
          const message = getMessage(todoIDs.length);

          const { hide } = this.$toast.show(
            message,
            undoMethod
              ? {
                  action: {
                    text: s__('Todos|Undo'),
                    onClick: () => {
                      hide();
                      this[undoMethod](todoIDs, false);
                    },
                  },
                }
              : {},
          );

          this.$emit('change');
        }
      } catch (failure) {
        Sentry.captureException(failure);
        this.$toast.show(s__('Todos|Action failed. Try again later.'), {
          variant: 'danger',
        });
      }
    },
  },
};
