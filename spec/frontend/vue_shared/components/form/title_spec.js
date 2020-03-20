import TitleField from '~/vue_shared/components/form/title.vue';
import { shallowMount } from '@vue/test-utils';

describe('Title edit field', () => {
  let wrapper;

  function createComponent() {
    wrapper = shallowMount(TitleField);
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('matches the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });
});
