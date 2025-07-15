import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TagsHeader from '~/packages_and_registries/harbor_registry/components/tags/tags_header.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { EMPTY_TAG_LABEL } from '~/packages_and_registries/harbor_registry/constants';
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
      propsData: {
        artifactDetail: mockArtifactDetail,
        pageInfo: mockPageInfo,
        tagsLoading: false,
      },
    });
  });

  describe('tags title', () => {
    it('should be artifact digest', () => {
      expect(findTitle().text()).toBe(`sha256:${MOCK_SHA_DIGEST}`);
    });
  });

  describe('tags count', () => {
    it('displays the tags count', () => {
      expect(findTagsCount().props('text')).toBe('1 tag');
    });

    describe('when pageInfo.total is NaN', () => {
      const nanMockPageInfo = {
        page: 1,
        perPage: 20,
        total: NaN,
        totalPages: 1,
      };

      beforeEach(() => {
        mountComponent({
          propsData: {
            artifactDetail: mockArtifactDetail,
            pageInfo: nanMockPageInfo,
            tagsLoading: false,
          },
        });
      });

      it('displays empty label when there are no tags', () => {
        expect(findTagsCount().props('text')).toBe(EMPTY_TAG_LABEL);
      });
    });

    describe('when pageInfo.total is 0', () => {
      const nanMockPageInfo = {
        page: 1,
        perPage: 20,
        total: 0,
        totalPages: 1,
      };

      beforeEach(() => {
        mountComponent({
          propsData: {
            artifactDetail: mockArtifactDetail,
            pageInfo: nanMockPageInfo,
            tagsLoading: false,
          },
        });
      });

      it('displays empty label when there are no tags', () => {
        expect(findTagsCount().props('text')).toBe(EMPTY_TAG_LABEL);
      });
    });
  });
});
