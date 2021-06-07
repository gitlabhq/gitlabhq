<script>
import { GlButton, GlButtonGroup, GlTooltipDirective } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import updateRunnerMutation from '~/runner/graphql/update_runner.mutation.graphql';

const i18n = {
  I18N_EDIT: __('Edit'),
  I18N_PAUSE: __('Pause'),
  I18N_RESUME: __('Resume'),
};

export default {
  components: {
    GlButton,
    GlButtonGroup,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      updating: false,
    };
  },
  computed: {
    runnerNumericalId() {
      return getIdFromGraphQLId(this.runner.id);
    },
    runnerUrl() {
      // TODO implement using webUrl from the API
      return `${gon.gitlab_url || ''}/admin/runners/${this.runnerNumericalId}`;
    },
    isActive() {
      return this.runner.active;
    },
    toggleActiveIcon() {
      return this.isActive ? 'pause' : 'play';
    },
    toggleActiveTitle() {
      if (this.updating) {
        // Prevent a "sticky" tooltip: If this button is disabled,
        // mouseout listeners will not run and the tooltip will
        // stay stuck on the button.
        return '';
      }
      return this.isActive ? i18n.I18N_PAUSE : i18n.I18N_RESUME;
    },
  },
  methods: {
    async onToggleActive() {
      this.updating = true;
      // TODO In HAML iteration we had a confirmation modal via:
      //   data-confirm="_('Are you sure?')"
      // this may not have to ported, this is an easily reversible operation

      try {
        const toggledActive = !this.runner.active;

        const {
          data: {
            runnerUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: updateRunnerMutation,
          variables: {
            input: {
              id: this.runner.id,
              active: toggledActive,
            },
          },
        });

        if (errors && errors.length) {
          this.onError(new Error(errors[0]));
        }
      } catch (e) {
        this.onError(e);
      } finally {
        this.updating = false;
      }
    },

    onError(error) {
      // TODO Render errors when "delete" action is done
      // `active` toggle would not fail due to user input.
      throw error;
    },
  },
  i18n,
};
</script>

<template>
  <gl-button-group>
    <gl-button
      v-gl-tooltip.hover.viewport
      :title="$options.i18n.I18N_EDIT"
      :aria-label="$options.i18n.I18N_EDIT"
      icon="pencil"
      :href="runnerUrl"
      data-testid="edit-runner"
    />
    <gl-button
      v-gl-tooltip.hover.viewport
      :title="toggleActiveTitle"
      :aria-label="toggleActiveTitle"
      :icon="toggleActiveIcon"
      :loading="updating"
      data-testid="toggle-active-runner"
      @click="onToggleActive"
    />
    <!-- TODO add delete action to update runners -->
  </gl-button-group>
</template>
