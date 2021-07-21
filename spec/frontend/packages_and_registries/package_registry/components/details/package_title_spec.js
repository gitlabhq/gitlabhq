import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PackageTags from '~/packages/shared/components/package_tags.vue';
import PackageTitle from '~/packages_and_registries/package_registry/components/details/package_title.vue';
import {
  PACKAGE_TYPE_CONAN,
  PACKAGE_TYPE_MAVEN,
  PACKAGE_TYPE_NPM,
  PACKAGE_TYPE_NUGET,
} from '~/packages_and_registries/package_registry/constants';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

import { packageData, packageFiles, packageTags, packagePipelines } from '../../mock_data';

const packageWithTags = {
  ...packageData(),
  tags: { nodes: packageTags() },
  packageFiles: { nodes: packageFiles() },
};

describe('PackageTitle', () => {
  let wrapper;

  function createComponent(packageEntity = packageWithTags) {
    wrapper = shallowMountExtended(PackageTitle, {
      propsData: { packageEntity },
      stubs: {
        TitleArea,
      },
    });
    return wrapper.vm.$nextTick();
  }

  const findTitleArea = () => wrapper.findComponent(TitleArea);
  const findPackageType = () => wrapper.findByTestId('package-type');
  const findPackageSize = () => wrapper.findByTestId('package-size');
  const findPipelineProject = () => wrapper.findByTestId('pipeline-project');
  const findPackageRef = () => wrapper.findByTestId('package-ref');
  const findPackageTags = () => wrapper.findComponent(PackageTags);
  const findPackageBadges = () => wrapper.findAllByTestId('tag-badge');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('renders', () => {
    it('without tags', async () => {
      await createComponent();

      expect(wrapper.element).toMatchSnapshot();
    });

    it('with tags', async () => {
      await createComponent();

      expect(wrapper.element).toMatchSnapshot();
    });

    it('with tags on mobile', async () => {
      jest.spyOn(GlBreakpointInstance, 'isDesktop').mockReturnValue(false);
      await createComponent();
      await wrapper.vm.$nextTick();

      expect(findPackageBadges()).toHaveLength(packageTags().length);
    });
  });

  describe('package title', () => {
    it('is correctly bound', async () => {
      await createComponent();

      expect(findTitleArea().props('title')).toBe(packageData().name);
    });
  });

  describe('package icon', () => {
    const iconUrl = 'a-fake-src';

    it('shows an icon when present and package type is NUGET', async () => {
      await createComponent({
        ...packageData(),
        packageType: PACKAGE_TYPE_NUGET,
        metadata: { iconUrl },
      });

      expect(findTitleArea().props('avatar')).toBe(iconUrl);
    });

    it('hides the icon when not present', async () => {
      await createComponent();

      expect(findTitleArea().props('avatar')).toBe(null);
    });
  });

  describe.each`
    packageType           | text
    ${PACKAGE_TYPE_CONAN} | ${'Conan'}
    ${PACKAGE_TYPE_MAVEN} | ${'Maven'}
    ${PACKAGE_TYPE_NPM}   | ${'npm'}
    ${PACKAGE_TYPE_NUGET} | ${'NuGet'}
  `(`package type`, ({ packageType, text }) => {
    beforeEach(() => createComponent({ ...packageData, packageType }));

    it(`${packageType} should render ${text}`, () => {
      expect(findPackageType().props()).toEqual(expect.objectContaining({ text, icon: 'package' }));
    });
  });

  describe('calculates the package size', () => {
    it('correctly calculates when there is only 1 file', async () => {
      await createComponent({ ...packageData(), packageFiles: { nodes: [packageFiles()[0]] } });

      expect(findPackageSize().props()).toMatchObject({ text: '400.00 KiB', icon: 'disk' });
    });

    it('correctly calculates when there are multiple files', async () => {
      await createComponent();

      expect(findPackageSize().props('text')).toBe('800.00 KiB');
    });
  });

  describe('package tags', () => {
    it('displays the package-tags component when the package has tags', async () => {
      await createComponent();

      expect(findPackageTags().exists()).toBe(true);
    });

    it('does not display the package-tags component when there are no tags', async () => {
      await createComponent({ ...packageData(), tags: { nodes: [] } });

      expect(findPackageTags().exists()).toBe(false);
    });
  });

  describe('package ref', () => {
    it('does not display the ref if missing', async () => {
      await createComponent();

      expect(findPackageRef().exists()).toBe(false);
    });

    it('correctly shows the package ref if there is one', async () => {
      await createComponent({
        ...packageData(),
        pipelines: { nodes: packagePipelines({ ref: 'test' }) },
      });
      expect(findPackageRef().props()).toMatchObject({
        text: 'test',
        icon: 'branch',
      });
    });
  });

  describe('pipeline project', () => {
    it('does not display the project if missing', async () => {
      await createComponent();

      expect(findPipelineProject().exists()).toBe(false);
    });

    it('correctly shows the pipeline project if there is one', async () => {
      await createComponent({
        ...packageData(),
        pipelines: { nodes: packagePipelines() },
      });
      expect(findPipelineProject().props()).toMatchObject({
        text: packagePipelines()[0].project.name,
        icon: 'review-list',
        link: packagePipelines()[0].project.webUrl,
      });
    });
  });
});
