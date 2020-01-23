import { shallowMount } from '@vue/test-utils';
import IdenticonComponent from '~/vue_shared/components/identicon.vue';

describe('Identicon', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(IdenticonComponent, {
      propsData: {
        entityId: 1,
        entityName: 'entity-name',
        sizeClass: 's40',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('matches snapshot', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('adds a correct class to identicon', () => {
    createComponent();

    expect(wrapper.find({ ref: 'identicon' }).classes()).toContain('bg2');
  });
});
