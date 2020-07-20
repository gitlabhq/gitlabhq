import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import component from '~/registry/explorer/components/details_page/empty_tags_state.vue';
import {
  EMPTY_IMAGE_REPOSITORY_TITLE,
  EMPTY_IMAGE_REPOSITORY_MESSAGE,
} from '~/registry/explorer/constants';

describe('EmptyTagsState component', () => {
  let wrapper;

  const findEmptyState = () => wrapper.find(GlEmptyState);

  const mountComponent = () => {
    wrapper = shallowMount(component, {
      stubs: {
        GlEmptyState,
      },
      propsData: {
        noContainersImage: 'foo',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('contains gl-empty-state', () => {
    mountComponent();
    expect(findEmptyState().exists()).toBe(true);
  });

  it('has the correct props', () => {
    mountComponent();
    expect(findEmptyState().props()).toMatchObject({
      title: EMPTY_IMAGE_REPOSITORY_TITLE,
      description: EMPTY_IMAGE_REPOSITORY_MESSAGE,
      svgPath: 'foo',
    });
  });
});
