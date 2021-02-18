import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import component from '~/registry/explorer/components/details_page/empty_state.vue';
import {
  NO_TAGS_TITLE,
  NO_TAGS_MESSAGE,
  MISSING_OR_DELETED_IMAGE_TITLE,
  MISSING_OR_DELETED_IMAGE_MESSAGE,
} from '~/registry/explorer/constants';

describe('EmptyTagsState component', () => {
  let wrapper;

  const findEmptyState = () => wrapper.find(GlEmptyState);

  const mountComponent = (propsData) => {
    wrapper = shallowMount(component, {
      stubs: {
        GlEmptyState,
      },
      propsData,
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

  it.each`
    isEmptyImage | title                             | description
    ${false}     | ${NO_TAGS_TITLE}                  | ${NO_TAGS_MESSAGE}
    ${true}      | ${MISSING_OR_DELETED_IMAGE_TITLE} | ${MISSING_OR_DELETED_IMAGE_MESSAGE}
  `(
    'when isEmptyImage is $isEmptyImage has the correct props',
    ({ isEmptyImage, title, description }) => {
      mountComponent({
        noContainersImage: 'foo',
        isEmptyImage,
      });

      expect(findEmptyState().props()).toMatchObject({
        title,
        description,
        svgPath: 'foo',
      });
    },
  );
});
