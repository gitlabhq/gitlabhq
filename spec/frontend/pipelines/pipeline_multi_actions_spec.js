import { nextTick } from 'vue';
import { GlAlert, GlDropdown, GlSprintf, GlLoadingIcon, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import PipelineMultiActions, {
  i18n,
} from '~/pipelines/components/pipelines_list/pipeline_multi_actions.vue';
import { TRACKING_CATEGORIES } from '~/pipelines/constants';

describe('Pipeline Multi Actions Dropdown', () => {
  let wrapper;
  let mockAxios;
  const focusInputMock = jest.fn();

  const artifacts = [
    {
      name: 'job my-artifact',
      path: '/download/path',
    },
    {
      name: 'job-2 my-artifact-2',
      path: '/download/path-two',
    },
  ];
  const artifactItemTestId = 'artifact-item';
  const artifactsEndpointPlaceholder = ':pipeline_artifacts_id';
  const artifactsEndpoint = `endpoint/${artifactsEndpointPlaceholder}/artifacts.json`;
  const pipelineId = 108;

  const createComponent = () => {
    wrapper = extendedWrapper(
      shallowMount(PipelineMultiActions, {
        provide: {
          artifactsEndpoint,
          artifactsEndpointPlaceholder,
        },
        propsData: {
          pipelineId,
        },
        stubs: {
          GlSprintf,
          GlDropdown,
          GlSearchBoxByType: stubComponent(GlSearchBoxByType, {
            methods: { focusInput: focusInputMock },
          }),
        },
      }),
    );
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAllArtifactItems = () => wrapper.findAllByTestId(artifactItemTestId);
  const findFirstArtifactItem = () => wrapper.findByTestId(artifactItemTestId);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findEmptyMessage = () => wrapper.findByTestId('artifacts-empty-message');

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  it('should render the dropdown', () => {
    createComponent();

    expect(findDropdown().exists()).toBe(true);
  });

  describe('Artifacts', () => {
    const endpoint = artifactsEndpoint.replace(artifactsEndpointPlaceholder, pipelineId);

    describe('while loading artifacts', () => {
      beforeEach(() => {
        mockAxios.onGet(endpoint).replyOnce(HTTP_STATUS_OK, { artifacts });
      });

      it('should render a loading spinner and no empty message', async () => {
        createComponent();

        findDropdown().vm.$emit('show');
        await nextTick();

        expect(findLoadingIcon().exists()).toBe(true);
        expect(findEmptyMessage().exists()).toBe(false);
      });
    });

    describe('artifacts loaded successfully', () => {
      describe('artifacts exist', () => {
        beforeEach(async () => {
          mockAxios.onGet(endpoint).replyOnce(HTTP_STATUS_OK, { artifacts });

          createComponent();

          findDropdown().vm.$emit('show');
          await waitForPromises();
        });

        it('should fetch artifacts and show search box on dropdown click', () => {
          expect(mockAxios.history.get).toHaveLength(1);
          expect(findSearchBox().exists()).toBe(true);
        });

        it('should focus the search box when opened with artifacts', () => {
          findDropdown().vm.$emit('shown');

          expect(focusInputMock).toHaveBeenCalled();
        });

        it('should render all the provided artifacts when search query is empty', () => {
          findSearchBox().vm.$emit('input', '');

          expect(findAllArtifactItems()).toHaveLength(artifacts.length);
          expect(findEmptyMessage().exists()).toBe(false);
        });

        it('should render filtered artifacts when search query is not empty', async () => {
          findSearchBox().vm.$emit('input', 'job-2');
          await waitForPromises();

          expect(findAllArtifactItems()).toHaveLength(1);
          expect(findEmptyMessage().exists()).toBe(false);
        });

        it('should render the correct artifact name and path', () => {
          expect(findFirstArtifactItem().attributes('href')).toBe(artifacts[0].path);
          expect(findFirstArtifactItem().text()).toBe(artifacts[0].name);
        });
      });

      describe('artifacts list is empty', () => {
        beforeEach(() => {
          mockAxios.onGet(endpoint).replyOnce(HTTP_STATUS_OK, { artifacts: [] });
        });

        it('should render empty message and no search box when no artifacts are found', async () => {
          createComponent();

          findDropdown().vm.$emit('show');
          await waitForPromises();

          expect(findEmptyMessage().exists()).toBe(true);
          expect(findSearchBox().exists()).toBe(false);
          expect(findLoadingIcon().exists()).toBe(false);
        });
      });
    });

    describe('with a failing request', () => {
      beforeEach(() => {
        mockAxios.onGet(endpoint).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it('should render an error message', async () => {
        createComponent();
        findDropdown().vm.$emit('show');
        await waitForPromises();

        const error = findAlert();
        expect(error.exists()).toBe(true);
        expect(error.text()).toBe(i18n.artifactsFetchErrorMessage);
      });
    });
  });

  describe('tracking', () => {
    afterEach(() => {
      unmockTracking();
    });

    it('tracks artifacts dropdown click', () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      createComponent();

      findDropdown().vm.$emit('show');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_artifacts_dropdown', {
        label: TRACKING_CATEGORIES.table,
      });
    });
  });
});
