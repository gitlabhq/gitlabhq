import { mount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import StorageTypeIcon from '~/usage_quotas/storage/components/storage_type_icon.vue';

describe('StorageTypeIcon', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(StorageTypeIcon, {
      propsData: {
        ...props,
      },
    });
  };

  const findGlIcon = () => wrapper.findComponent(GlIcon);

  describe('rendering icon', () => {
    it.each`
      expected                     | provided
      ${'doc-image'}               | ${'lfsObjects'}
      ${'snippet'}                 | ${'snippets'}
      ${'infrastructure-registry'} | ${'repository'}
      ${'package'}                 | ${'packages'}
      ${'disk'}                    | ${'wiki'}
      ${'disk'}                    | ${'anything-else'}
    `(
      'renders icon with name of $expected when name prop is $provided',
      ({ expected, provided }) => {
        createComponent({ name: provided });

        expect(findGlIcon().props('name')).toBe(expected);
      },
    );
  });
});
