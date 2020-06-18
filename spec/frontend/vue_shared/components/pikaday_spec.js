import { shallowMount } from '@vue/test-utils';
import datePicker from '~/vue_shared/components/pikaday.vue';

describe('datePicker', () => {
  let wrapper;
  beforeEach(() => {
    wrapper = shallowMount(datePicker, {
      propsData: {
        label: 'label',
      },
      attachToDocument: true,
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should render label text', () => {
    expect(
      wrapper
        .find('.dropdown-toggle-text')
        .text()
        .trim(),
    ).toEqual('label');
  });

  it('should show calendar', () => {
    expect(wrapper.find('.pika-single').element).toBeDefined();
  });

  it('should emit hidePicker event when dropdown is clicked', () => {
    // Removing the bootstrap data-toggle property,
    // because it interfers with our click event
    delete wrapper.find('.dropdown-menu-toggle').element.dataset.toggle;

    wrapper.find('.dropdown-menu-toggle').trigger('click');

    expect(wrapper.emitted('hidePicker')).toEqual([[]]);
  });
});
