import { nextTick } from 'vue';
import {
  GlAlert,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlSprintf,
  GlLoadingIcon,
  GlSearchBoxByType,
} from '@gitlab/ui';
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
} from '~/ci/pipelines_page/components/pipeline_multi_actions.vue';
import { TRACKING_CATEGORIES } from '~/ci/constants';

describe('Pipeline Multi Actions Dropdown', () => {
  let wrapper;
  let mockAxios;

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
  const newArtifacts = [
    {
      name: 'job-3 my-new-artifact',
      path: '/new/download/path',
    },
    {
      name: 'job-4 my-new-artifact-2',
      path: '/new/download/path-two',
    },
    {
      name: 'job-5 my-new-artifact-3',
      path: '/new/download/path-three',
    },
  ];
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
          GlAlert,
          GlSprintf,
          GlDisclosureDropdown,
          GlDisclosureDropdownItem,
          GlSearchBoxByType: stubComponent(GlSearchBoxByType),
        },
      }),
    );
  };

  const findAlert = () => wrapper.findByTestId('artifacts-fetch-error');
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAllArtifactItemsData = () =>
    findDropdown()
      .props('items')
      .map(({ text, href }) => ({
        name: text,
        path: href,
      }));
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findEmptyMessage = () => wrapper.findByTestId('artifacts-empty-message');
  const findWarning = () => wrapper.findByTestId('artifacts-fetch-warning');
  const changePipelineId = (newId) => wrapper.setProps({ pipelineId: newId });

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

        findDropdown().vm.$emit('shown');
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

          findDropdown().vm.$emit('shown');
          await waitForPromises();
        });

        it('should fetch artifacts and show search box on dropdown click', () => {
          expect(mockAxios.history.get).toHaveLength(1);
          expect(findSearchBox().exists()).toBe(true);
        });

        it('should focus the search box when opened with artifacts', () => {
          findDropdown().vm.$emit('shown');

          expect(findSearchBox().attributes('autofocus')).not.toBe(undefined);
        });

        it('should clear searchQuery when dropdown is closed', async () => {
          findDropdown().vm.$emit('shown');
          findSearchBox().vm.$emit('input', 'job-2');
          await waitForPromises();

          expect(findSearchBox().vm.value).toBe('job-2');

          findDropdown().vm.$emit('hidden');
          await waitForPromises();

          expect(findSearchBox().vm.value).toBe('');
        });

        it('should render all the provided artifacts when search query is empty', async () => {
          findSearchBox().vm.$emit('input', '');
          await waitForPromises();

          expect(findAllArtifactItemsData()).toEqual(
            artifacts.map(({ name, path }) => ({ name, path })),
          );
          expect(findEmptyMessage().exists()).toBe(false);
        });

        it('should render filtered artifacts when search query is not empty', async () => {
          findSearchBox().vm.$emit('input', 'job-2');
          await waitForPromises();

          expect(findAllArtifactItemsData()).toEqual([
            {
              name: 'job-2 my-artifact-2',
              path: '/download/path-two',
            },
          ]);
          expect(findEmptyMessage().exists()).toBe(false);
        });

        it('should render the correct artifact name and path', () => {
          expect(findAllArtifactItemsData()).toEqual(artifacts);
        });

        describe('when opened again with new artifacts', () => {
          describe('with a successful refetch', () => {
            beforeEach(async () => {
              mockAxios.resetHistory();
              mockAxios.onGet(endpoint).replyOnce(HTTP_STATUS_OK, { artifacts: newArtifacts });

              findDropdown().vm.$emit('shown');
              await nextTick();
            });

            it('should hide list and render a loading spinner on dropdown click', () => {
              expect(findAllArtifactItemsData()).toHaveLength(0);
              expect(findLoadingIcon().exists()).toBe(true);
            });

            it('should not render warning or empty message while loading', () => {
              expect(findEmptyMessage().exists()).toBe(false);
              expect(findWarning().exists()).toBe(false);
            });

            it('should render the correct new list', async () => {
              await waitForPromises();

              expect(findAllArtifactItemsData()).toEqual(newArtifacts);
            });
          });

          describe('with a failing refetch', () => {
            beforeEach(async () => {
              mockAxios.onGet(endpoint).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

              findDropdown().vm.$emit('shown');
              await waitForPromises();
            });

            it('should render warning', () => {
              expect(findWarning().text()).toBe(i18n.artifactsFetchWarningMessage);
            });

            it('should render old list', () => {
              expect(findAllArtifactItemsData()).toEqual(artifacts);
            });
          });
        });

        describe('pipeline id has changed', () => {
          const newEndpoint = artifactsEndpoint.replace(
            artifactsEndpointPlaceholder,
            pipelineId + 1,
          );

          beforeEach(() => {
            changePipelineId(pipelineId + 1);
          });

          describe('followed by a failing request', () => {
            beforeEach(async () => {
              mockAxios.onGet(newEndpoint).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

              findDropdown().vm.$emit('shown');
              await waitForPromises();
            });

            it('should render error message and no warning', () => {
              expect(findWarning().exists()).toBe(false);
              expect(findAlert().text()).toBe(i18n.artifactsFetchErrorMessage);
            });

            it('should clear list', () => {
              expect(findAllArtifactItemsData()).toHaveLength(0);
            });
          });
        });
      });

      describe('artifacts list is empty', () => {
        beforeEach(() => {
          mockAxios.onGet(endpoint).replyOnce(HTTP_STATUS_OK, { artifacts: [] });
        });

        it('should render empty message and no search box when no artifacts are found', async () => {
          createComponent();

          findDropdown().vm.$emit('shown');
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
        findDropdown().vm.$emit('shown');
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

      findDropdown().vm.$emit('shown');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_artifacts_dropdown', {
        label: TRACKING_CATEGORIES.table,
      });
    });
  });
});
