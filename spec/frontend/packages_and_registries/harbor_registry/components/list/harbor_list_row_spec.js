import { shallowMount, RouterLinkStub as RouterLink } from '@vue/test-utils';
import { GlIcon, GlSkeletonLoader } from '@gitlab/ui';

import HarborListRow from '~/packages_and_registries/harbor_registry/components/list/harbor_list_row.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { harborImagesList } from '../../mock_data';

describe('Harbor List Row', () => {
  let wrapper;
  const item = harborImagesList[0];

  const findDetailsLink = () => wrapper.findComponent(RouterLink);
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findArtifactsCount = () => wrapper.find('[data-testid="artifacts-count"]');
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  const mountComponent = (props) => {
    wrapper = shallowMount(HarborListRow, {
      stubs: {
        RouterLink,
        ListItem,
      },
      propsData: {
        item,
        ...props,
      },
    });
  };

  describe('image title and path', () => {
    it('contains a link to the details page', () => {
      mountComponent();

      const link = findDetailsLink();
      expect(link.text()).toBe(item.name);
      expect(findDetailsLink().props('to')).toMatchObject({
        name: 'details',
        params: {
          image: 'nginx',
          project: 'nginx',
        },
      });
    });

    it('contains a clipboard button', () => {
      mountComponent();
      const button = findClipboardButton();
      expect(button.exists()).toBe(true);
      expect(button.props('text')).toBe(item.location);
      expect(button.props('title')).toBe(item.location);
    });
  });

  describe('artifacts count', () => {
    it('exists', () => {
      mountComponent();
      expect(findArtifactsCount().exists()).toBe(true);
    });

    it('contains a package icon', () => {
      mountComponent();
      const icon = findArtifactsCount().findComponent(GlIcon);
      expect(icon.exists()).toBe(true);
      expect(icon.props('name')).toBe('package');
    });

    describe('loading state', () => {
      it('shows a loader when metadataLoading is true', () => {
        mountComponent({ metadataLoading: true });

        expect(findSkeletonLoader().exists()).toBe(true);
      });

      it('hides the artifacts count while loading', () => {
        mountComponent({ metadataLoading: true });

        expect(findArtifactsCount().exists()).toBe(false);
      });
    });

    describe('artifacts count text', () => {
      it('with one artifact in the image', () => {
        mountComponent({ item: { ...item, artifactCount: 1 } });

        expect(findArtifactsCount().text()).toMatchInterpolatedText('1 artifact');
      });
      it('with more than one artifact in the image', () => {
        mountComponent({ item: { ...item, artifactCount: 3 } });

        expect(findArtifactsCount().text()).toMatchInterpolatedText('3 artifacts');
      });
    });
  });
});
