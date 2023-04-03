import { shallowMount } from '@vue/test-utils';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import UsageGraph from '~/usage_quotas/storage/components/usage_graph.vue';

let data;
let wrapper;

function mountComponent({ rootStorageStatistics, limit }) {
  wrapper = shallowMount(UsageGraph, {
    propsData: {
      rootStorageStatistics,
      limit,
    },
  });
}
function findStorageTypeUsagesSerialized() {
  return wrapper
    .findAll('[data-testid="storage-type-usage"]')
    .wrappers.map((wp) => wp.element.style.flex);
}

describe('Storage Counter usage graph component', () => {
  beforeEach(() => {
    data = {
      rootStorageStatistics: {
        wikiSize: 5000,
        repositorySize: 4000,
        packagesSize: 3000,
        containerRegistrySize: 2500,
        lfsObjectsSize: 2000,
        buildArtifactsSize: 700,
        pipelineArtifactsSize: 300,
        snippetsSize: 2000,
        storageSize: 17000,
      },
      limit: 2000,
    };
    mountComponent(data);
  });

  it('renders the legend in order', () => {
    const types = wrapper.findAll('[data-testid="storage-type-legend"]');

    const {
      buildArtifactsSize,
      pipelineArtifactsSize,
      lfsObjectsSize,
      packagesSize,
      containerRegistrySize,
      repositorySize,
      wikiSize,
      snippetsSize,
    } = data.rootStorageStatistics;

    expect(types.at(0).text()).toMatchInterpolatedText(`Wiki ${numberToHumanSize(wikiSize)}`);
    expect(types.at(1).text()).toMatchInterpolatedText(
      `Repository ${numberToHumanSize(repositorySize)}`,
    );
    expect(types.at(2).text()).toMatchInterpolatedText(
      `Packages ${numberToHumanSize(packagesSize)}`,
    );
    expect(types.at(3).text()).toMatchInterpolatedText(
      `Container Registry ${numberToHumanSize(containerRegistrySize)}`,
    );
    expect(types.at(4).text()).toMatchInterpolatedText(`LFS ${numberToHumanSize(lfsObjectsSize)}`);
    expect(types.at(5).text()).toMatchInterpolatedText(
      `Snippets ${numberToHumanSize(snippetsSize)}`,
    );
    expect(types.at(6).text()).toMatchInterpolatedText(
      `Job artifacts ${numberToHumanSize(buildArtifactsSize)}`,
    );
    expect(types.at(7).text()).toMatchInterpolatedText(
      `Pipeline artifacts ${numberToHumanSize(pipelineArtifactsSize)}`,
    );
  });

  describe('when storage type is not used', () => {
    beforeEach(() => {
      data.rootStorageStatistics.wikiSize = 0;
      mountComponent(data);
    });

    it('filters the storage type', () => {
      expect(wrapper.text()).not.toContain('Wikis');
    });
  });

  describe('when there is no storage usage', () => {
    beforeEach(() => {
      data.rootStorageStatistics.storageSize = 0;
      mountComponent(data);
    });

    it('does not render', () => {
      expect(wrapper.html()).toEqual('');
    });
  });

  describe('when limit is 0', () => {
    beforeEach(() => {
      data.limit = 0;
      mountComponent(data);
    });

    it('sets correct flex values', () => {
      expect(findStorageTypeUsagesSerialized()).toStrictEqual([
        '0.29411764705882354',
        '0.23529411764705882',
        '0.17647058823529413',
        '0.14705882352941177',
        '0.11764705882352941',
        '0.11764705882352941',
        '0.041176470588235294',
        '0.01764705882352941',
      ]);
    });
  });

  describe('when storage exceeds limit', () => {
    beforeEach(() => {
      data.limit = data.rootStorageStatistics.storageSize - 1;
      mountComponent(data);
    });

    it('does render correclty', () => {
      expect(findStorageTypeUsagesSerialized()).toStrictEqual([
        '0.29411764705882354',
        '0.23529411764705882',
        '0.17647058823529413',
        '0.14705882352941177',
        '0.11764705882352941',
        '0.11764705882352941',
        '0.041176470588235294',
        '0.01764705882352941',
      ]);
    });
  });
});
