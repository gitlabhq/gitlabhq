import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { n__ } from '~/locale';
import ArtifactsListRow from '~/packages_and_registries/harbor_registry/components/details/artifacts_list_row.vue';
import RealListItem from '~/vue_shared/components/registry/list_item.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { harborArtifactsList, defaultConfig } from '../../mock_data';

describe('Harbor artifact list row', () => {
  let wrapper;

  const ListItem = {
    ...RealListItem,
    data() {
      return {
        detailsSlots: [],
        isDetailsShown: true,
      };
    },
  };

  const RouterLinkStub = {
    props: {
      to: {
        type: Object,
      },
    },
    render(createElement) {
      return createElement('a', {}, this.$slots.default);
    },
  };

  const findListItem = () => wrapper.findComponent(ListItem);
  const findClipboardButton = () => wrapper.findAllComponents(ClipboardButton);
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const findByTestId = (testId) => wrapper.findByTestId(testId);

  const $route = {
    params: {
      project: defaultConfig.harborIntegrationProjectName,
      image: 'test-repository',
    },
  };

  const mountComponent = ({ propsData, config = defaultConfig }) => {
    wrapper = shallowMountExtended(ArtifactsListRow, {
      stubs: {
        GlSprintf,
        ListItem,
        'router-link': RouterLinkStub,
      },
      mocks: {
        $route,
      },
      propsData,
      provide() {
        return {
          ...config,
        };
      },
    });
  };

  describe('list item', () => {
    beforeEach(() => {
      mountComponent({
        propsData: {
          artifact: harborArtifactsList[0],
        },
      });
    });

    it('exists', () => {
      expect(findListItem().exists()).toBe(true);
    });

    it('has the correct artifact name', () => {
      expect(findByTestId('name').text()).toBe(harborArtifactsList[0].digest);
    });

    it('has the correct tags count', () => {
      const tagsCount = harborArtifactsList[0].tags.length;
      expect(findByTestId('tags-count').text()).toBe(n__('%d tag', '%d tags', tagsCount));
    });

    it('has correct digest', () => {
      expect(findByTestId('digest').text()).toBe('Digest: mock_sh');
    });
    describe('time', () => {
      it('has the correct push time', () => {
        expect(findByTestId('time').text()).toBe('Published');
        expect(findTimeAgoTooltip().attributes()).toMatchObject({
          time: harborArtifactsList[0].pushTime,
        });
      });
    });

    describe('clipboard button', () => {
      it('exists', () => {
        expect(findClipboardButton()).toHaveLength(2);
      });

      it('has the correct props', () => {
        expect(findClipboardButton().at(0).attributes()).toMatchObject({
          text: `docker pull demo.harbor.com/test-project/test-repository@${harborArtifactsList[0].digest}`,
          title: `docker pull demo.harbor.com/test-project/test-repository@${harborArtifactsList[0].digest}`,
        });

        expect(findClipboardButton().at(1).attributes()).toMatchObject({
          text: harborArtifactsList[0].digest,
          title: harborArtifactsList[0].digest,
        });
      });
    });

    describe('size', () => {
      it('calculated correctly', () => {
        expect(findByTestId('size').text()).toBe(
          numberToHumanSize(Number(harborArtifactsList[0].size)),
        );
      });

      it('when size is missing', () => {
        const artifactInfo = harborArtifactsList[0];
        artifactInfo.size = null;

        mountComponent({
          propsData: {
            artifact: artifactInfo,
          },
        });

        expect(findByTestId('size').text()).toBe('0 B');
      });
    });
  });
});
