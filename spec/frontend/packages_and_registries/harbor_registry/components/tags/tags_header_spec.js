import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TagsHeader from '~/packages_and_registries/harbor_registry/components/tags/tags_header.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { mockArtifactDetail, MOCK_SHA_DIGEST } from '../../mock_data';

describe('Harbor Tags Header', () => {
  let wrapper;

  const findTitle = () => wrapper.findByTestId('title');
  const findTagsCount = () => wrapper.findByTestId('tags-count');

  const mountComponent = ({ propsData }) => {
    wrapper = shallowMountExtended(TagsHeader, {
      propsData,
      stubs: {
        TitleArea,
      },
    });
  };

  const mockPageInfo = {
    page: 1,
    perPage: 20,
    total: 1,
    totalPages: 1,
  };

  beforeEach(() => {
    mountComponent({
      propsData: { artifactDetail: mockArtifactDetail, pageInfo: mockPageInfo, tagsLoading: false },
    });
  });

  describe('tags title', () => {
    it('should be artifact digest', () => {
      expect(findTitle().text()).toBe(`sha256:${MOCK_SHA_DIGEST}`);
    });
  });

  describe('tags count', () => {
    it('would has the correct text', async () => {
      await nextTick();

      expect(findTagsCount().props('text')).toBe('1 tag');
    });
  });
});
