import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import component from '~/packages_and_registries/infrastructure_registry/details/components/details_title.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { terraformModule, mavenFiles, npmPackage } from '../../mock_data';

Vue.use(Vuex);

describe('PackageTitle', () => {
  let wrapper;
  let store;

  async function createComponent({
    packageFiles = mavenFiles,
    packageEntity = terraformModule,
  } = {}) {
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
      store,
      stubs: {
        TitleArea,
      },
    });
    await nextTick();
  }

  const findTitleArea = () => wrapper.findComponent(TitleArea);
  const packageSize = () => wrapper.find('[data-testid="package-size"]');
  const pipelineProject = () => wrapper.find('[data-testid="pipeline-project"]');
  const packageRef = () => wrapper.find('[data-testid="package-ref"]');

  describe('module title', () => {
    it('is correctly bound', async () => {
      await createComponent();

      expect(findTitleArea().props('title')).toBe(terraformModule.name);
    });
  });

  describe('calculates the package size', () => {
    it('correctly calculates the size', async () => {
      await createComponent();

      expect(packageSize().props('text')).toBe('300 B');
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
