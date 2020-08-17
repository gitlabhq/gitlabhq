import { shallowMount } from '@vue/test-utils';
import TitleField from '~/vue_shared/components/form/title.vue';

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
