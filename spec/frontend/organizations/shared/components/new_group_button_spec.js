import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import NewGroupButton from '~/organizations/shared/components/new_group_button.vue';

describe('NewGroupButton', () => {
  let wrapper;

  const defaultProvide = {
    canCreateGroup: false,
    newGroupPath: '',
  };

  const defaultProps = {
    category: 'primary',
  };

  function createComponent({ provide = {}, props = {} } = {}) {
    wrapper = shallowMount(NewGroupButton, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  }

  const findGlButton = () => wrapper.findComponent(GlButton);

  describe.each`
    canCreateGroup | newGroupPath
    ${false}       | ${null}
    ${false}       | ${'/asdf'}
    ${true}        | ${null}
  `(
    'when `canCreateGroup` is $canCreateGroup and `newGroupPath` is $newGroupPath',
    ({ canCreateGroup, newGroupPath }) => {
      beforeEach(() => {
        createComponent({ provide: { canCreateGroup, newGroupPath } });
      });

      it('renders nothing', () => {
        expect(wrapper.find('*').exists()).toBe(false);
      });
    },
  );

  describe('when `canCreateGroup` is true and `newGroupPath` is /asdf', () => {
    const newGroupPath = '/asdf';

    describe('with no category', () => {
      beforeEach(() => {
        createComponent({
          provide: { canCreateGroup: true, newGroupPath },
          props: { category: undefined },
        });
      });

      it('renders GlButton correctly', () => {
        expect(findGlButton().attributes('href')).toBe(newGroupPath);
        expect(findGlButton().props('category')).toBe(defaultProps.category);
      });
    });

    describe('with set category', () => {
      const category = 'secondary';

      beforeEach(() => {
        createComponent({ provide: { canCreateGroup: true, newGroupPath }, props: { category } });
      });

      it('renders GlButton correctly', () => {
        expect(findGlButton().attributes('href')).toBe(newGroupPath);
        expect(findGlButton().props('category')).toBe(category);
      });
    });
  });
});
