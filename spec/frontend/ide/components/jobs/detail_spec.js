import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';

import { TEST_HOST } from 'helpers/test_constants';
import JobDetail from '~/ide/components/jobs/detail.vue';
import { createStore } from '~/ide/stores';
import { jobs } from '../../mock_data';

describe('IDE jobs detail view', () => {
  let wrapper;
  let store;

  const createComponent = () => {
    store = createStore();

    store.state.pipelines.detailJob = {
      ...jobs[0],
      isLoading: true,
      output: 'testing',
      rawPath: `${TEST_HOST}/raw`,
    };

    jest.spyOn(store, 'dispatch');
    store.dispatch.mockResolvedValue();

    wrapper = mount(JobDetail, { store });
  };

  const findBuildJobLog = () => wrapper.find('pre');
  const findScrollToBottomButton = () => wrapper.find('button[aria-label="Scroll to bottom"]');
  const findScrollToTopButton = () => wrapper.find('button[aria-label="Scroll to top"]');

  beforeEach(() => {
    createComponent();
  });

  describe('mounted', () => {
    const findJobOutput = () => wrapper.find('.bash');
    const findBuildLoaderAnimation = () => wrapper.find('.build-loader-animation');

    it('calls fetchJobLogs', () => {
      expect(store.dispatch).toHaveBeenCalledWith('pipelines/fetchJobLogs', undefined);
    });

    it('scrolls to bottom', () => {
      expect(findBuildJobLog().element.scrollTo).toHaveBeenCalled();
    });

    it('renders job output', () => {
      expect(findJobOutput().text()).toContain('testing');
    });

    it('renders empty message output', async () => {
      store.state.pipelines.detailJob.output = '';
      await nextTick();

      expect(findJobOutput().text()).toContain('No messages were logged');
    });

    it('renders loading icon', () => {
      expect(findBuildLoaderAnimation().exists()).toBe(true);
      expect(findBuildLoaderAnimation().isVisible()).toBe(true);
    });

    it('hides output when loading', () => {
      expect(findJobOutput().exists()).toBe(true);
      expect(findJobOutput().isVisible()).toBe(false);
    });

    it('hide loading icon when isLoading is false', async () => {
      store.state.pipelines.detailJob.isLoading = false;
      await nextTick();

      expect(findBuildLoaderAnimation().isVisible()).toBe(false);
    });

    it('resets detailJob when clicking header button', async () => {
      await wrapper.find('.btn').trigger('click');

      expect(store.dispatch).toHaveBeenCalledWith('pipelines/setDetailJob', null);
    });

    it('renders raw path link', () => {
      expect(wrapper.find('.controllers-buttons').attributes('href')).toBe(`${TEST_HOST}/raw`);
    });
  });

  describe('scroll buttons', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      fnName           | btnName   | scrollPos | targetScrollPos
      ${'scroll down'} | ${'down'} | ${0}      | ${200}
      ${'scroll up'}   | ${'up'}   | ${200}    | ${0}
    `('triggers $fnName when clicking $btnName button', async ({ scrollPos, targetScrollPos }) => {
      jest.spyOn(findBuildJobLog().element, 'offsetHeight', 'get').mockReturnValue(0);
      jest.spyOn(findBuildJobLog().element, 'scrollHeight', 'get').mockReturnValue(200);
      jest.spyOn(findBuildJobLog().element, 'scrollTop', 'get').mockReturnValue(scrollPos);
      findBuildJobLog().element.scrollTo.mockReset();

      await findBuildJobLog().trigger('scroll'); // trigger button updates

      await wrapper.find('.controllers button:not(:disabled)').trigger('click');

      expect(findBuildJobLog().element.scrollTo).toHaveBeenCalledWith(0, targetScrollPos);
    });
  });

  describe('scrolling build log', () => {
    beforeEach(() => {
      jest.spyOn(findBuildJobLog().element, 'offsetHeight', 'get').mockReturnValue(100);
      jest.spyOn(findBuildJobLog().element, 'scrollHeight', 'get').mockReturnValue(200);
    });

    it('keeps scroll at bottom when already at the bottom', async () => {
      jest.spyOn(findBuildJobLog().element, 'scrollTop', 'get').mockReturnValue(100);

      await findBuildJobLog().trigger('scroll');

      expect(findScrollToBottomButton().attributes('disabled')).toBeDefined();
      expect(findScrollToTopButton().attributes('disabled')).toBeUndefined();
    });

    it('keeps scroll at top when already at top', async () => {
      jest.spyOn(findBuildJobLog().element, 'scrollTop', 'get').mockReturnValue(0);

      await findBuildJobLog().trigger('scroll');

      expect(findScrollToBottomButton().attributes('disabled')).toBeUndefined();
      expect(findScrollToTopButton().attributes('disabled')).toBeDefined();
    });

    it('resets scroll when not at top or bottom', async () => {
      jest.spyOn(findBuildJobLog().element, 'scrollTop', 'get').mockReturnValue(10);

      await findBuildJobLog().trigger('scroll');

      expect(findScrollToBottomButton().attributes('disabled')).toBeUndefined();
      expect(findScrollToTopButton().attributes('disabled')).toBeUndefined();
    });
  });
});
