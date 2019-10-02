import Visibility from 'visibilityjs';
import { GlLoadingIcon } from '@gitlab/ui';
import Poll from '~/lib/utils/poll';
import flash from '~/flash';
import CommitPipelineStatus from '~/projects/tree/components/commit_pipeline_status_component.vue';
import { shallowMount } from '@vue/test-utils';
import { getJSONFixture } from '../helpers/fixtures';

jest.mock('~/lib/utils/poll');
jest.mock('visibilityjs');
jest.mock('~/flash');

const mockFetchData = jest.fn();
jest.mock('~/projects/tree/services/commit_pipeline_service', () =>
  jest.fn().mockImplementation(() => ({
    fetchData: mockFetchData.mockReturnValue(Promise.resolve()),
  })),
);

describe('Commit pipeline status component', () => {
  let wrapper;
  const { pipelines } = getJSONFixture('pipelines/pipelines.json');
  const { status: mockCiStatus } = pipelines[0].details;

  const defaultProps = {
    endpoint: 'endpoint',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(CommitPipelineStatus, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      sync: false,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    jest.clearAllMocks();
  });

  describe('Visibility management', () => {
    describe('when component is hidden', () => {
      beforeEach(() => {
        Visibility.hidden.mockReturnValue(true);
        createComponent();
      });

      it('does not start polling', () => {
        const [pollInstance] = Poll.mock.instances;
        expect(pollInstance.makeRequest).not.toHaveBeenCalled();
      });

      it('requests pipeline data', () => {
        expect(mockFetchData).toHaveBeenCalled();
      });
    });

    describe('when component is visible', () => {
      beforeEach(() => {
        Visibility.hidden.mockReturnValue(false);
        createComponent();
      });

      it('starts polling', () => {
        const [pollInstance] = [...Poll.mock.instances].reverse();
        expect(pollInstance.makeRequest).toHaveBeenCalled();
      });
    });

    describe('when component changes its visibility', () => {
      it.each`
        visibility | action
        ${false}   | ${'restart'}
        ${true}    | ${'stop'}
      `(
        '$action polling when component visibility becomes $visibility',
        ({ visibility, action }) => {
          Visibility.hidden.mockReturnValue(!visibility);
          createComponent();
          const [pollInstance] = Poll.mock.instances;
          expect(pollInstance[action]).not.toHaveBeenCalled();
          Visibility.hidden.mockReturnValue(visibility);
          const [visibilityHandler] = Visibility.change.mock.calls[0];
          visibilityHandler();
          expect(pollInstance[action]).toHaveBeenCalled();
        },
      );
    });
  });

  it('stops polling when component is destroyed', () => {
    createComponent();
    wrapper.destroy();
    const [pollInstance] = Poll.mock.instances;
    expect(pollInstance.stop).toHaveBeenCalled();
  });

  describe('when polling', () => {
    let pollConfig;
    beforeEach(() => {
      Poll.mockImplementation(config => {
        pollConfig = config;
        return { makeRequest: jest.fn(), restart: jest.fn(), stop: jest.fn() };
      });
      createComponent();
    });

    it('shows the loading icon at start', () => {
      createComponent();
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);

      pollConfig.successCallback({
        data: { pipelines: [] },
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
      });
    });

    describe('is successful', () => {
      beforeEach(() => {
        pollConfig.successCallback({
          data: { pipelines: [{ details: { status: mockCiStatus } }] },
        });
        return wrapper.vm.$nextTick();
      });

      it('renders CI icon without loader', () => {
        expect(wrapper.element).toMatchSnapshot();
      });
    });

    describe('is not successful', () => {
      beforeEach(() => {
        pollConfig.errorCallback();
      });

      it('renders not found CI icon without loader', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('displays flash error message', () => {
        expect(flash).toHaveBeenCalled();
      });
    });
  });
});
