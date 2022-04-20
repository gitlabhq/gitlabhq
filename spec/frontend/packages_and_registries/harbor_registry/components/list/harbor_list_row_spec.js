import { shallowMount, RouterLinkStub as RouterLink } from '@vue/test-utils';
import { GlIcon, GlSprintf, GlSkeletonLoader } from '@gitlab/ui';

import HarborListRow from '~/packages_and_registries/harbor_registry/components/list/harbor_list_row.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { harborListResponse } from '../../mock_data';

describe('Harbor List Row', () => {
  let wrapper;
  const [item] = harborListResponse.repositories;

  const findDetailsLink = () => wrapper.find(RouterLink);
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findTagsCount = () => wrapper.find('[data-testid="tags-count"]');
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  const mountComponent = (props) => {
    wrapper = shallowMount(HarborListRow, {
      stubs: {
        RouterLink,
        GlSprintf,
        ListItem,
      },
      propsData: {
        item,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('image title and path', () => {
    it('contains a link to the details page', () => {
      mountComponent();

      const link = findDetailsLink();
      expect(link.text()).toBe(item.name);
      expect(findDetailsLink().props('to')).toMatchObject({
        name: 'details',
        params: {
          id: item.id,
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

  describe('tags count', () => {
    it('exists', () => {
      mountComponent();
      expect(findTagsCount().exists()).toBe(true);
    });

    it('contains a tag icon', () => {
      mountComponent();
      const icon = findTagsCount().find(GlIcon);
      expect(icon.exists()).toBe(true);
      expect(icon.props('name')).toBe('tag');
    });

    describe('loading state', () => {
      it('shows a loader when metadataLoading is true', () => {
        mountComponent({ metadataLoading: true });

        expect(findSkeletonLoader().exists()).toBe(true);
      });

      it('hides the tags count while loading', () => {
        mountComponent({ metadataLoading: true });

        expect(findTagsCount().exists()).toBe(false);
      });
    });

    describe('tags count text', () => {
      it('with one tag in the image', () => {
        mountComponent({ item: { ...item, artifactCount: 1 } });

        expect(findTagsCount().text()).toMatchInterpolatedText('1 Tag');
      });
      it('with more than one tag in the image', () => {
        mountComponent({ item: { ...item, artifactCount: 3 } });

        expect(findTagsCount().text()).toMatchInterpolatedText('3 Tags');
      });
    });
  });
});
