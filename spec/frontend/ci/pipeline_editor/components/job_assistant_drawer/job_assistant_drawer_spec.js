import { GlDrawer } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import JobAssistantDrawer from '~/ci/pipeline_editor/components/job_assistant_drawer/job_assistant_drawer.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';

Vue.use(VueApollo);

describe('Job assistant drawer', () => {
  let wrapper;

  const findDrawer = () => wrapper.findComponent(GlDrawer);

  const findCancelButton = () => wrapper.findByTestId('cancel-button');

  const createComponent = () => {
    wrapper = mountExtended(JobAssistantDrawer, {
      propsData: {
        isVisible: true,
      },
    });
  };

  beforeEach(async () => {
    createComponent();
    await waitForPromises();
  });

  it('should emit close job assistant drawer event when closing the drawer', () => {
    expect(wrapper.emitted('close-job-assistant-drawer')).toBeUndefined();

    findDrawer().vm.$emit('close');

    expect(wrapper.emitted('close-job-assistant-drawer')).toHaveLength(1);
  });

  it('should emit close job assistant drawer event when click cancel button', () => {
    expect(wrapper.emitted('close-job-assistant-drawer')).toBeUndefined();

    findCancelButton().trigger('click');

    expect(wrapper.emitted('close-job-assistant-drawer')).toHaveLength(1);
  });
});
