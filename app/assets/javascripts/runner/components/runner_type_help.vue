<script>
import {
  INSTANCE_TYPE,
  GROUP_TYPE,
  PROJECT_TYPE,
  I18N_INSTANCE_RUNNER_DESCRIPTION,
  I18N_GROUP_RUNNER_DESCRIPTION,
  I18N_PROJECT_RUNNER_DESCRIPTION,
  I18N_LOCKED_RUNNER_DESCRIPTION,
  I18N_PAUSED_RUNNER_DESCRIPTION,
} from '../constants';
import RunnerTypeBadge from './runner_type_badge.vue';
import RunnerStateLockedBadge from './runner_state_locked_badge.vue';
import RunnerStatePausedBadge from './runner_state_paused_badge.vue';

export default {
  components: {
    RunnerTypeBadge,
    RunnerStateLockedBadge,
    RunnerStatePausedBadge,
  },
  runnerTypes: {
    INSTANCE_TYPE,
    GROUP_TYPE,
    PROJECT_TYPE,
  },
  i18n: {
    I18N_INSTANCE_RUNNER_DESCRIPTION,
    I18N_GROUP_RUNNER_DESCRIPTION,
    I18N_PROJECT_RUNNER_DESCRIPTION,
    I18N_LOCKED_RUNNER_DESCRIPTION,
    I18N_PAUSED_RUNNER_DESCRIPTION,
  },
};
</script>

<template>
  <div class="bs-callout">
    <p>{{ __('Runners are processes that pick up and execute CI/CD jobs for GitLab.') }}</p>
    <p>
      {{
        __(
          'You can register runners as separate users, on separate servers, and on your local machine. Register as many runners as you want.',
        )
      }}
    </p>

    <div>
      <span> {{ __('Runners can be:') }}</span>
      <ul>
        <li>
          <runner-type-badge :type="$options.runnerTypes.INSTANCE_TYPE" size="sm" />
          - {{ $options.i18n.I18N_INSTANCE_RUNNER_DESCRIPTION }}
        </li>
        <li>
          <runner-type-badge :type="$options.runnerTypes.GROUP_TYPE" size="sm" />
          - {{ $options.i18n.I18N_GROUP_RUNNER_DESCRIPTION }}
        </li>
        <li>
          <runner-type-badge :type="$options.runnerTypes.PROJECT_TYPE" size="sm" />
          - {{ $options.i18n.I18N_PROJECT_RUNNER_DESCRIPTION }}
        </li>
        <li>
          <runner-state-locked-badge size="sm" />
          - {{ $options.i18n.I18N_LOCKED_RUNNER_DESCRIPTION }}
        </li>
        <li>
          <runner-state-paused-badge size="sm" />
          - {{ $options.i18n.I18N_PAUSED_RUNNER_DESCRIPTION }}
        </li>
      </ul>
    </div>
  </div>
</template>
