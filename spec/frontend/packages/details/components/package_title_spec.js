import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import PackageTitle from '~/packages/details/components/package_title.vue';
import PackageTags from '~/packages/shared/components/package_tags.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import {
  conanPackage,
  mavenFiles,
  mavenPackage,
  mockTags,
  npmFiles,
  npmPackage,
  nugetPackage,
} from '../../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('PackageTitle', () => {
  let wrapper;
  let store;

  function createComponent({
    packageEntity = mavenPackage,
    packageFiles = mavenFiles,
    icon = null,
  } = {}) {
    store = new Vuex.Store({
      state: {
        packageEntity,
        packageFiles,
      },
      getters: {
        packageTypeDisplay: ({ packageEntity: { package_type: type } }) => type,
        packagePipeline: ({ packageEntity: { pipeline = null } }) => pipeline,
        packageIcon: () => icon,
      },
    });

    wrapper = shallowMount(PackageTitle, {
      localVue,
      store,
      stubs: {
        TitleArea,
      },
    });
    return wrapper.vm.$nextTick();
  }

  const findTitleArea = () => wrapper.find(TitleArea);
  const packageType = () => wrapper.find('[data-testid="package-type"]');
  const packageSize = () => wrapper.find('[data-testid="package-size"]');
  const pipelineProject = () => wrapper.find('[data-testid="pipeline-project"]');
  const packageRef = () => wrapper.find('[data-testid="package-ref"]');
  const packageTags = () => wrapper.find(PackageTags);
  const packageBadges = () => wrapper.findAll('[data-testid="tag-badge"]');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('renders', () => {
    it('without tags', async () => {
      await createComponent();

      expect(wrapper.element).toMatchSnapshot();
    });

    it('with tags', async () => {
      await createComponent({ packageEntity: { ...mavenPackage, tags: mockTags } });

      expect(wrapper.element).toMatchSnapshot();
    });

    it('with tags on mobile', async () => {
      jest.spyOn(GlBreakpointInstance, 'isDesktop').mockReturnValue(false);
      await createComponent({ packageEntity: { ...mavenPackage, tags: mockTags } });
      await wrapper.vm.$nextTick();

      expect(packageBadges()).toHaveLength(mockTags.length);
    });
  });

  describe('package title', () => {
    it('is correctly bound', async () => {
      await createComponent();

      expect(findTitleArea().props('title')).toBe('Test package');
    });
  });

  describe('package icon', () => {
    const fakeSrc = 'a-fake-src';

    it('binds an icon when provided one from vuex', async () => {
      await createComponent({ icon: fakeSrc });

      expect(findTitleArea().props('avatar')).toBe(fakeSrc);
    });

    it('do not binds an icon when not provided one', async () => {
      await createComponent();

      expect(findTitleArea().props('avatar')).toBe(null);
    });
  });

  describe.each`
    packageEntity   | text
    ${conanPackage} | ${'conan'}
    ${mavenPackage} | ${'maven'}
    ${npmPackage}   | ${'npm'}
    ${nugetPackage} | ${'nuget'}
  `(`package type`, ({ packageEntity, text }) => {
    beforeEach(() => createComponent({ packageEntity }));

    it(`${packageEntity.package_type} should render from Vuex getters ${text}`, () => {
      expect(packageType().props()).toEqual(expect.objectContaining({ text, icon: 'package' }));
    });
  });

  describe('calculates the package size', () => {
    it('correctly calculates when there is only 1 file', async () => {
      await createComponent({ packageEntity: npmPackage, packageFiles: npmFiles });

      expect(packageSize().props()).toMatchObject({ text: '200 bytes', icon: 'disk' });
    });

    it('correctly calulates when there are multiple files', async () => {
      await createComponent();

      expect(packageSize().props('text')).toBe('300 bytes');
    });
  });

  describe('package tags', () => {
    it('displays the package-tags component when the package has tags', async () => {
      await createComponent({
        packageEntity: {
          ...npmPackage,
          tags: mockTags,
        },
      });

      expect(packageTags().exists()).toBe(true);
    });

    it('does not display the package-tags component when there are no tags', async () => {
      await createComponent();

      expect(packageTags().exists()).toBe(false);
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
