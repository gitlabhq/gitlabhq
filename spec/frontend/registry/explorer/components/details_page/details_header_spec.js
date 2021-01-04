import { shallowMount } from '@vue/test-utils';
import { GlSprintf } from '@gitlab/ui';
import { useFakeDate } from 'helpers/fake_date';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import component from '~/registry/explorer/components/details_page/details_header.vue';
import { DETAILS_PAGE_TITLE } from '~/registry/explorer/constants';

describe('Details Header', () => {
  let wrapper;

  const defaultImage = {
    name: 'foo',
    updatedAt: '2020-11-03T13:29:21Z',
    project: {
      visibility: 'public',
    },
  };

  // set the date to Dec 4, 2020
  useFakeDate(2020, 11, 4);

  const findLastUpdatedAndVisibility = () => wrapper.find('[data-testid="updated-and-visibility"]');

  const waitForMetadataItems = async () => {
    // Metadata items are printed by a loop in the title-area and it takes two ticks for them to be available
    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();
  };

  const mountComponent = (image = defaultImage) => {
    wrapper = shallowMount(component, {
      propsData: {
        image,
      },
      stubs: {
        GlSprintf,
        TitleArea,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('has the correct title ', () => {
    mountComponent({ ...defaultImage, name: '' });
    expect(wrapper.text()).toMatchInterpolatedText(DETAILS_PAGE_TITLE);
  });

  it('shows imageName in the title', () => {
    mountComponent();
    expect(wrapper.text()).toContain('foo');
  });

  it('has a metadata item with last updated text', async () => {
    mountComponent();
    await waitForMetadataItems();

    expect(findLastUpdatedAndVisibility().props('text')).toBe('Last updated 1 month ago');
  });

  describe('visibility icon', () => {
    it('shows an eye when the project is public', async () => {
      mountComponent();
      await waitForMetadataItems();

      expect(findLastUpdatedAndVisibility().props('icon')).toBe('eye');
    });
    it('shows an eye slashed when the project is not public', async () => {
      mountComponent({ ...defaultImage, project: { visibility: 'private' } });
      await waitForMetadataItems();

      expect(findLastUpdatedAndVisibility().props('icon')).toBe('eye-slash');
    });
  });
});
