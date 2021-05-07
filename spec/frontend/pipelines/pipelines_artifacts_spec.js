import { GlAlert, GlDropdown, GlDropdownItem, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import PipelineArtifacts, {
  i18n,
} from '~/pipelines/components/pipelines_list/pipelines_artifacts.vue';

describe('Pipelines Artifacts dropdown', () => {
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
  const artifactsEndpointPlaceholder = ':pipeline_artifacts_id';
  const artifactsEndpoint = `endpoint/${artifactsEndpointPlaceholder}/artifacts.json`;
  const pipelineId = 108;

  const createComponent = ({ mockData = {} } = {}) => {
    wrapper = shallowMount(PipelineArtifacts, {
      provide: {
        artifactsEndpoint,
        artifactsEndpointPlaceholder,
      },
      propsData: {
        pipelineId,
      },
      data() {
        return {
          ...mockData,
        };
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findFirstGlDropdownItem = () => wrapper.find(GlDropdownItem);
  const findAllGlDropdownItems = () => wrapper.find(GlDropdown).findAll(GlDropdownItem);

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should render the dropdown', () => {
    createComponent();

    expect(findDropdown().exists()).toBe(true);
  });

  it('should fetch artifacts on dropdown click', async () => {
    const endpoint = artifactsEndpoint.replace(artifactsEndpointPlaceholder, pipelineId);
    mockAxios.onGet(endpoint).replyOnce(200, { artifacts });
    createComponent();
    findDropdown().vm.$emit('show');
    await waitForPromises();

    expect(mockAxios.history.get).toHaveLength(1);
    expect(wrapper.vm.artifacts).toEqual(artifacts);
  });

  it('should render a dropdown with all the provided artifacts', () => {
    createComponent({ mockData: { artifacts } });

    expect(findAllGlDropdownItems()).toHaveLength(artifacts.length);
  });

  it('should render a link with the provided path', () => {
    createComponent({ mockData: { artifacts } });

    expect(findFirstGlDropdownItem().attributes('href')).toBe(artifacts[0].path);

    expect(findFirstGlDropdownItem().text()).toBe(`Download ${artifacts[0].name} artifact`);
  });

  describe('with a failing request', () => {
    it('should render an error message', async () => {
      const endpoint = artifactsEndpoint.replace(artifactsEndpointPlaceholder, pipelineId);
      mockAxios.onGet(endpoint).replyOnce(500);
      createComponent();
      findDropdown().vm.$emit('show');
      await waitForPromises();

      const error = findAlert();
      expect(error.exists()).toBe(true);
      expect(error.text()).toBe(i18n.artifactsFetchErrorMessage);
    });
  });

  describe('with no artifacts received', () => {
    it('should render empty alert message', () => {
      createComponent({ mockData: { artifacts: [] } });

      const emptyAlert = findAlert();
      expect(emptyAlert.exists()).toBe(true);
      expect(emptyAlert.text()).toBe(i18n.noArtifacts);
    });
  });

  describe('when artifacts are loading', () => {
    it('should show loading icon', () => {
      createComponent({ mockData: { isLoading: true } });

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });
});
