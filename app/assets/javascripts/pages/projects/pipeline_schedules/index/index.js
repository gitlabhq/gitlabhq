import Vue from 'vue';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import initPipelineSchedulesApp from '~/ci/pipeline_schedules/mount_pipeline_schedules_app';
import PipelineSchedulesTakeOwnershipModalLegacy from '~/ci/pipeline_schedules/components/take_ownership_modal_legacy.vue';
import PipelineSchedulesCallout from '../shared/components/pipeline_schedules_callout.vue';

function initPipelineSchedulesCallout() {
  const el = document.getElementById('pipeline-schedules-callout');

  if (!el) {
    return;
  }

  const { docsUrl, illustrationUrl } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'PipelineSchedulesCalloutRoot',
    provide: {
      docsUrl,
      illustrationUrl,
    },
    render(createElement) {
      return createElement(PipelineSchedulesCallout);
    },
  });
}

// TODO: move take ownership feature into new Vue app
// located in directory app/assets/javascripts/pipeline_schedules/components
function initTakeownershipModal() {
  const modalId = 'pipeline-take-ownership-modal';
  const buttonSelector = 'js-take-ownership-button';
  const el = document.getElementById(modalId);
  const takeOwnershipButtons = document.querySelectorAll(`.${buttonSelector}`);

  if (!el) {
    return;
  }

  // eslint-disable-next-line no-new
  new Vue({
    el,
    data() {
      return {
        url: '',
      };
    },
    mounted() {
      takeOwnershipButtons.forEach((button) => {
        button.addEventListener('click', () => {
          const { url } = button.dataset;

          this.url = url;
          this.$root.$emit(BV_SHOW_MODAL, modalId, `.${buttonSelector}`);
        });
      });
    },
    render(createElement) {
      return createElement(PipelineSchedulesTakeOwnershipModalLegacy, {
        props: {
          ownershipUrl: this.url,
        },
      });
    },
  });
}

if (gon.features?.pipelineSchedulesVue) {
  initPipelineSchedulesApp();
} else {
  initPipelineSchedulesCallout();
  initTakeownershipModal();
}
