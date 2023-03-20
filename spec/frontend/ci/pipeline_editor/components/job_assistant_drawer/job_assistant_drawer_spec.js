import { GlDrawer } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { stringify } from 'yaml';
import JobAssistantDrawer from '~/ci/pipeline_editor/components/job_assistant_drawer/job_assistant_drawer.vue';
import JobSetupItem from '~/ci/pipeline_editor/components/job_assistant_drawer/accordion_items/job_setup_item.vue';
import ImageItem from '~/ci/pipeline_editor/components/job_assistant_drawer/accordion_items/image_item.vue';
import getAllRunners from '~/ci/runner/graphql/list/all_runners.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createStore from '~/ci/pipeline_editor/store';
import { mockAllRunnersQueryResponse } from 'jest/ci/pipeline_editor/mock_data';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import eventHub, { SCROLL_EDITOR_TO_BOTTOM } from '~/ci/pipeline_editor/event_hub';

Vue.use(VueApollo);

describe('Job assistant drawer', () => {
  let wrapper;
  let mockApollo;

  const dummyJobName = 'a';
  const dummyJobScript = 'b';
  const dummyImageName = 'c';
  const dummyImageEntrypoint = 'd';

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findJobSetupItem = () => wrapper.findComponent(JobSetupItem);
  const findImageItem = () => wrapper.findComponent(ImageItem);

  const findConfirmButton = () => wrapper.findByTestId('confirm-button');
  const findCancelButton = () => wrapper.findByTestId('cancel-button');

  const createComponent = () => {
    mockApollo = createMockApollo([
      [getAllRunners, jest.fn().mockResolvedValue(mockAllRunnersQueryResponse)],
    ]);

    wrapper = mountExtended(JobAssistantDrawer, {
      store: createStore(),
      propsData: {
        isVisible: true,
      },
      apolloProvider: mockApollo,
    });
  };

  beforeEach(async () => {
    createComponent();
    await waitForPromises();
  });

  it('should contain job setup accordion', () => {
    expect(findJobSetupItem().exists()).toBe(true);
  });

  it('should contain image accordion', () => {
    expect(findImageItem().exists()).toBe(true);
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

  it('trigger validate if job name is empty', async () => {
    const updateCiConfigSpy = jest.spyOn(wrapper.vm, 'updateCiConfig');
    findJobSetupItem().vm.$emit('update-job', 'script', 'b');
    findConfirmButton().trigger('click');

    await nextTick();

    expect(findJobSetupItem().props('isNameValid')).toBe(false);
    expect(findJobSetupItem().props('isScriptValid')).toBe(true);
    expect(updateCiConfigSpy).toHaveBeenCalledTimes(0);
  });

  describe('when enter valid input', () => {
    beforeEach(() => {
      findJobSetupItem().vm.$emit('update-job', 'name', dummyJobName);
      findJobSetupItem().vm.$emit('update-job', 'script', dummyJobScript);
      findImageItem().vm.$emit('update-job', 'image.name', dummyImageName);
      findImageItem().vm.$emit('update-job', 'image.entrypoint', [dummyImageEntrypoint]);
    });

    it('passes correct prop to accordions', () => {
      const accordions = [findJobSetupItem(), findImageItem()];
      accordions.forEach((accordion) => {
        expect(accordion.props('job')).toMatchObject({
          name: dummyJobName,
          script: dummyJobScript,
          image: {
            name: dummyImageName,
            entrypoint: [dummyImageEntrypoint],
          },
        });
      });
    });

    it('job name and script state should be valid', () => {
      expect(findJobSetupItem().props('isNameValid')).toBe(true);
      expect(findJobSetupItem().props('isScriptValid')).toBe(true);
    });

    it('should clear job data when click confirm button', async () => {
      findConfirmButton().trigger('click');

      await nextTick();

      expect(findJobSetupItem().props('job')).toMatchObject({ name: '', script: '' });
    });

    it('should clear job data when click cancel button', async () => {
      findCancelButton().trigger('click');

      await nextTick();

      expect(findJobSetupItem().props('job')).toMatchObject({ name: '', script: '' });
    });

    it('should update correct ci content when click add button', () => {
      const updateCiConfigSpy = jest.spyOn(wrapper.vm, 'updateCiConfig');

      findConfirmButton().trigger('click');

      expect(updateCiConfigSpy).toHaveBeenCalledWith(
        `\n${stringify({
          [dummyJobName]: {
            script: dummyJobScript,
            image: { name: dummyImageName, entrypoint: [dummyImageEntrypoint] },
          },
        })}`,
      );
    });

    it('should emit scroll editor to button event when click add button', () => {
      const eventHubSpy = jest.spyOn(eventHub, '$emit');

      findConfirmButton().trigger('click');

      expect(eventHubSpy).toHaveBeenCalledWith(SCROLL_EDITOR_TO_BOTTOM);
    });
  });
});
