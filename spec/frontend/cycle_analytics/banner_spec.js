import { shallowMount } from '@vue/test-utils';
import Banner from '~/cycle_analytics/components/banner.vue';

describe('Value Stream Analytics banner', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(Banner, {
      propsData: {
        documentationLink: 'path',
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render value stream analytics information', () => {
    expect(wrapper.find('h4').text().trim()).toBe('Introducing Value Stream Analytics');

    expect(
      wrapper
        .find('p')
        .text()
        .trim()
        .replace(/[\r\n]+/g, ' '),
    ).toContain(
      'Value Stream Analytics gives an overview of how much time it takes to go from idea to production in your project.',
    );

    expect(wrapper.find('a').text().trim()).toBe('Read more');
    expect(wrapper.find('a').attributes('href')).toBe('path');
  });

  it('should emit an event when close button is clicked', async () => {
    jest.spyOn(wrapper.vm, '$emit').mockImplementation(() => {});

    await wrapper.find('.js-ca-dismiss-button').trigger('click');

    expect(wrapper.vm.$emit).toHaveBeenCalled();
  });
});
