import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { terraformModule, mavenFiles, npmPackage } from 'jest/packages/mock_data';
import component from '~/packages_and_registries/infrastructure_registry/components/details_title.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('PackageTitle', () => {
  let wrapper;
  let store;

  function createComponent({ packageFiles = mavenFiles, packageEntity = terraformModule } = {}) {
    store = new Vuex.Store({
      state: {
        packageEntity,
        packageFiles,
      },
      getters: {
        packagePipeline: ({ packageEntity: { pipeline = null } }) => pipeline,
      },
    });

    wrapper = shallowMount(component, {
      localVue,
      store,
      stubs: {
        TitleArea,
      },
    });
    return wrapper.vm.$nextTick();
  }

  const findTitleArea = () => wrapper.findComponent(TitleArea);
  const packageSize = () => wrapper.find('[data-testid="package-size"]');
  const pipelineProject = () => wrapper.find('[data-testid="pipeline-project"]');
  const packageRef = () => wrapper.find('[data-testid="package-ref"]');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('module title', () => {
    it('is correctly bound', async () => {
      await createComponent();

      expect(findTitleArea().props('title')).toBe(terraformModule.name);
    });
  });

  describe('calculates the package size', () => {
    it('correctly calculates the size', async () => {
      await createComponent();

      expect(packageSize().props('text')).toBe('300 bytes');
    });
  });

  describe('package ref', () => {
    it('does not display the ref if missing', async () => {
      await createComponent();

      expect(packageRef().exists()).toBe(false);
    });

    it('correctly shows the package ref if there is one', async () => {
      await createComponent({ packageEntity: npmPackage });
      expect(packageRef().props()).toMatchObject({
        text: npmPackage.pipeline.ref,
        icon: 'branch',
      });
    });
  });

  describe('pipeline project', () => {
    it('does not display the project if missing', async () => {
      await createComponent();

      expect(pipelineProject().exists()).toBe(false);
    });

    it('correctly shows the pipeline project if there is one', async () => {
      await createComponent({ packageEntity: npmPackage });

      expect(pipelineProject().props()).toMatchObject({
        text: npmPackage.pipeline.project.name,
        icon: 'review-list',
        link: npmPackage.pipeline.project.web_url,
      });
    });
  });
});
