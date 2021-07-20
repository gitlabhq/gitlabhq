<script>
import { GlBadge } from '@gitlab/ui';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '../constants';
import RunnerTypeBadge from './runner_type_badge.vue';

export default {
  components: {
    GlBadge,
    RunnerTypeBadge,
  },
  runnerTypes: {
    INSTANCE_TYPE,
    GROUP_TYPE,
    PROJECT_TYPE,
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
          - {{ __('Runs jobs from all unassigned projects.') }}
        </li>
        <li>
          <runner-type-badge :type="$options.runnerTypes.GROUP_TYPE" size="sm" />
          - {{ __('Runs jobs from all unassigned projects in its group.') }}
        </li>
        <li>
          <runner-type-badge :type="$options.runnerTypes.PROJECT_TYPE" size="sm" />
          - {{ __('Runs jobs from assigned projects.') }}
        </li>
        <li>
          <gl-badge variant="warning" size="sm">
            {{ s__('Runners|locked') }}
          </gl-badge>
          - {{ __('Cannot be assigned to other projects.') }}
        </li>
        <li>
          <gl-badge variant="danger" size="sm">
            {{ s__('Runners|paused') }}
          </gl-badge>
          - {{ __('Not available to run jobs.') }}
        </li>
      </ul>
    </div>
  </div>
</template>
