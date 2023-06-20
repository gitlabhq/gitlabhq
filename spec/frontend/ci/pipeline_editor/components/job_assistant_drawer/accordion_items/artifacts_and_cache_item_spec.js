import { GlLink, GlSprintf } from '@gitlab/ui';
import ArtifactsAndCacheItem from '~/ci/pipeline_editor/components/job_assistant_drawer/accordion_items/artifacts_and_cache_item.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  JOB_TEMPLATE,
  HELP_PATHS,
} from '~/ci/pipeline_editor/components/job_assistant_drawer/constants';

describe('Artifacts and cache item', () => {
  let wrapper;

  const findLinks = () => wrapper.findAllComponents(GlLink);
  const findArtifactsPathsInputByIndex = (index) =>
    wrapper.findByTestId(`artifacts-paths-input-${index}`);
  const findArtifactsExcludeInputByIndex = (index) =>
    wrapper.findByTestId(`artifacts-exclude-input-${index}`);
  const findCachePathsInputByIndex = (index) => wrapper.findByTestId(`cache-paths-input-${index}`);
  const findCacheKeyInput = () => wrapper.findByTestId('cache-key-input');
  const findDeleteArtifactsPathsButtonByIndex = (index) =>
    wrapper.findByTestId(`delete-artifacts-paths-button-${index}`);
  const findDeleteArtifactsExcludeButtonByIndex = (index) =>
    wrapper.findByTestId(`delete-artifacts-exclude-button-${index}`);
  const findDeleteCachePathsButtonByIndex = (index) =>
    wrapper.findByTestId(`delete-cache-paths-button-${index}`);
  const findAddArtifactsPathsButton = () => wrapper.findByTestId('add-artifacts-paths-button');
  const findAddArtifactsExcludeButton = () => wrapper.findByTestId('add-artifacts-exclude-button');
  const findAddCachePathsButton = () => wrapper.findByTestId('add-cache-paths-button');

  const dummyArtifactsPath = 'dummyArtifactsPath';
  const dummyArtifactsExclude = 'dummyArtifactsExclude';
  const dummyCachePath = 'dummyCachePath';
  const dummyCacheKey = 'dummyCacheKey';

  const createComponent = ({ job = JSON.parse(JSON.stringify(JOB_TEMPLATE)) } = {}) => {
    wrapper = shallowMountExtended(ArtifactsAndCacheItem, {
      propsData: {
        job,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  it('should render help links with correct hrefs', () => {
    createComponent();

    const hrefs = findLinks().wrappers.map((w) => w.attributes('href'));
    expect(hrefs).toEqual([HELP_PATHS.artifactsHelpPath, HELP_PATHS.cacheHelpPath]);
  });

  it('should emit update job event when filling inputs', () => {
    createComponent();

    expect(wrapper.emitted('update-job')).toBeUndefined();

    findArtifactsPathsInputByIndex(0).vm.$emit('input', dummyArtifactsPath);

    expect(wrapper.emitted('update-job')).toHaveLength(1);
    expect(wrapper.emitted('update-job')[0]).toStrictEqual([
      'artifacts.paths[0]',
      dummyArtifactsPath,
    ]);

    findArtifactsExcludeInputByIndex(0).vm.$emit('input', dummyArtifactsExclude);

    expect(wrapper.emitted('update-job')).toHaveLength(2);
    expect(wrapper.emitted('update-job')[1]).toStrictEqual([
      'artifacts.exclude[0]',
      dummyArtifactsExclude,
    ]);

    findCachePathsInputByIndex(0).vm.$emit('input', dummyCachePath);

    expect(wrapper.emitted('update-job')).toHaveLength(3);
    expect(wrapper.emitted('update-job')[2]).toStrictEqual(['cache.paths[0]', dummyCachePath]);

    findCacheKeyInput().vm.$emit('input', dummyCacheKey);

    expect(wrapper.emitted('update-job')).toHaveLength(4);
    expect(wrapper.emitted('update-job')[3]).toStrictEqual(['cache.key', dummyCacheKey]);
  });

  it('should emit update job event when click add item button', () => {
    createComponent();

    findAddArtifactsPathsButton().vm.$emit('click');

    expect(wrapper.emitted('update-job')).toHaveLength(1);
    expect(wrapper.emitted('update-job')[0]).toStrictEqual(['artifacts.paths[1]', '']);

    findAddArtifactsExcludeButton().vm.$emit('click');

    expect(wrapper.emitted('update-job')).toHaveLength(2);
    expect(wrapper.emitted('update-job')[1]).toStrictEqual(['artifacts.exclude[1]', '']);

    findAddCachePathsButton().vm.$emit('click');

    expect(wrapper.emitted('update-job')).toHaveLength(3);
    expect(wrapper.emitted('update-job')[2]).toStrictEqual(['cache.paths[1]', '']);
  });

  it('should emit update job event when click delete item button', () => {
    createComponent({
      job: {
        artifacts: {
          paths: ['0', '1'],
          exclude: ['0', '1'],
        },
        cache: {
          paths: ['0', '1'],
          key: '',
        },
      },
    });

    findDeleteArtifactsPathsButtonByIndex(0).vm.$emit('click');

    expect(wrapper.emitted('update-job')).toHaveLength(1);
    expect(wrapper.emitted('update-job')[0]).toStrictEqual(['artifacts.paths[0]']);

    findDeleteArtifactsExcludeButtonByIndex(0).vm.$emit('click');

    expect(wrapper.emitted('update-job')).toHaveLength(2);
    expect(wrapper.emitted('update-job')[1]).toStrictEqual(['artifacts.exclude[0]']);

    findDeleteCachePathsButtonByIndex(0).vm.$emit('click');

    expect(wrapper.emitted('update-job')).toHaveLength(3);
    expect(wrapper.emitted('update-job')[2]).toStrictEqual(['cache.paths[0]']);
  });

  it('should not emit update job event when click the only one delete item button', () => {
    createComponent();

    findDeleteArtifactsPathsButtonByIndex(0).vm.$emit('click');
    findDeleteArtifactsExcludeButtonByIndex(0).vm.$emit('click');
    findDeleteCachePathsButtonByIndex(0).vm.$emit('click');

    expect(wrapper.emitted('update-job')).toBeUndefined();
  });
});
