<script>
import runnerTogglePausedMutation from '~/ci/runner/graphql/shared/runner_toggle_paused.mutation.graphql';
import { createAlert } from '~/alert';
import { captureException } from '~/ci/runner/sentry_utils';

/**
 * Renderless component that wraps a GraphQL pause mutation for the
 * runner, given its id and current "paused" value.
 *
 * You can use the slot to define a presentation for the delete action,
 * like a button or dropdown item.

 * Usage:
 *
 * ```vue
 * <runner-pause-action
 *   #default="{ loading, onClick }"
 *   :runner="runner"
 *   @done="onToggled"
 * >
 *   <button :disabled="loading" @click="onClick">{{ runner.paused ? 'Go!' : 'Stop!' }}</button>
 * </runner-pause-action>
 * ```
 *
 */
export default {
  name: 'RunnerPauseAction',
  props: {
    runner: {
      type: Object,
      required: true,
    },
    compact: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['done'],
  data() {
    return {
      loading: false,
    };
  },
  methods: {
    async onClick() {
      this.loading = true;
      try {
        const input = {
          id: this.runner.id,
          paused: !this.runner.paused,
        };

        const {
          data: {
            runnerUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: runnerTogglePausedMutation,
          variables: {
            input,
          },
        });

        if (errors && errors.length) {
          throw new Error(errors.join(' '));
        }
        this.$emit('done');
      } catch (e) {
        this.onError(e);
      } finally {
        this.loading = false;
      }
    },
    onError(error) {
      const { message } = error;

      createAlert({ message });
      captureException({ error, component: this.$options.name });
    },
  },
  render() {
    return this.$scopedSlots.default({
      onClick: this.onClick,
      loading: this.loading,
    });
  },
};
</script>
