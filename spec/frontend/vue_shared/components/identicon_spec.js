import { shallowMount } from '@vue/test-utils';
import IdenticonComponent from '~/vue_shared/components/identicon.vue';

describe('Identicon', () => {
  let wrapper;

  const defaultProps = {
    entityId: 1,
    entityName: 'entity-name',
    sizeClass: 's40',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(IdenticonComponent, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('entity id is a number', () => {
    beforeEach(createComponent);

    it('matches snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('adds a correct class to identicon', () => {
      expect(wrapper.find({ ref: 'identicon' }).classes()).toContain('bg2');
    });
  });

  describe('entity id is a GraphQL id', () => {
    beforeEach(() => createComponent({ entityId: 'gid://gitlab/Project/8' }));

    it('matches snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('adds a correct class to identicon', () => {
      expect(wrapper.find({ ref: 'identicon' }).classes()).toContain('bg2');
    });
  });
});
