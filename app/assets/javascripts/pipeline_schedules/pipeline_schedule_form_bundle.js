import Vue from 'vue';
import Translate from '../vue_shared/translate';
import intervalPatternInput from './components/interval_pattern_input.vue';
import TimezoneDropdown from './components/timezone_dropdown';
import TargetBranchDropdown from './components/target_branch_dropdown';
import { setupPipelineVariableList } from './setup_pipeline_variable_list';

Vue.use(Translate);

function initIntervalPatternInput() {
  const intervalPatternMount = document.getElementById('interval-pattern-input');
  const initialCronInterval = intervalPatternMount ? intervalPatternMount.dataset.initialInterval : '';

  return new Vue({
    el: intervalPatternMount,
    components: {
      intervalPatternInput,
    },
    render(createElement) {
      return createElement('interval-pattern-input', {
        props: {
          initialCronInterval,
        },
      });
    },
  });
}

document.addEventListener('DOMContentLoaded', () => {
  /* Most of the form is written in haml, but for fields with more complex behaviors,
   * you should mount individual Vue components here. If at some point components need
   * to share state, it may make sense to refactor the whole form to Vue */

  initIntervalPatternInput();

  // Initialize non-Vue JS components in the form

  const formElement = document.getElementById('new-pipeline-schedule-form');

  gl.timezoneDropdown = new TimezoneDropdown();
  gl.targetBranchDropdown = new TargetBranchDropdown();
  gl.pipelineScheduleFieldErrors = new gl.GlFieldErrors(formElement);

  setupPipelineVariableList($('.js-pipeline-variable-list'));
});
